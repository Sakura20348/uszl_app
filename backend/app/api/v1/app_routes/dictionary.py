from fastapi import APIRouter, HTTPException, Query, Response, status
from sqlalchemy import delete, func, or_, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import selectinload

from app.deps import DB, CurrentUser, OptionalUser
from app.models import Category, OfflinePackage, RecentView, SavedSign, Sign, SignCategory
from app.schemas.common import Page
from app.schemas.dictionary import (
    CategoryOut,
    OfflinePackageOut,
    RecentViewOut,
    SavedSignOut,
    SignBrief,
    SignKind,
    SignOut,
)

router = APIRouter()

# How many recently viewed signs are kept per user
RECENT_LIMIT = 50


def sign_query():
    return select(Sign).options(selectinload(Sign.videos), selectinload(Sign.categories), selectinload(Sign.related))


def search_filter(q: str):
    pattern = f"%{q.strip()}%"
    return or_(
        Sign.word.ilike(pattern),
        Sign.translation_ru.ilike(pattern),
        Sign.translation_en.ilike(pattern),
        Sign.transcription.ilike(pattern),
    )


@router.get("/categories", response_model=list[CategoryOut])
async def list_categories(db: DB, featured: bool | None = None, emergency: bool | None = None) -> list[CategoryOut]:
    counts = (
        select(SignCategory.category_id, func.count().label("n"))
        .join(Sign, Sign.id == SignCategory.sign_id)
        .where(Sign.is_published.is_(True))
        .group_by(SignCategory.category_id)
        .subquery()
    )
    query = select(Category, func.coalesce(counts.c.n, 0)).outerjoin(counts, counts.c.category_id == Category.id)
    if featured is not None:
        query = query.where(Category.is_featured.is_(featured))
    if emergency is not None:
        query = query.where(Category.is_emergency.is_(emergency))
    rows = await db.execute(query.order_by(Category.order, Category.id))
    return [CategoryOut.model_validate(c).model_copy(update={"sign_count": n}) for c, n in rows.all()]


@router.get("/signs", response_model=Page[SignBrief])
async def list_signs(
    db: DB,
    category: str | None = Query(default=None, description="Category slug"),
    q: str | None = Query(default=None, max_length=100, description="Search in Uzbek, Russian or English"),
    kind: SignKind | None = None,
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> Page[SignBrief]:
    where = [Sign.is_published.is_(True)]
    if category:
        where.append(Sign.categories.any(Category.slug == category))
    if q:
        where.append(search_filter(q))
    if kind:
        where.append(Sign.kind == kind)
    total = await db.scalar(select(func.count()).select_from(Sign).where(*where)) or 0
    rows = await db.scalars(select(Sign).where(*where).order_by(Sign.word, Sign.id).limit(limit).offset(offset))
    return Page(items=[SignBrief.model_validate(s) for s in rows], total=total)


@router.get("/signs/{sign_id}", response_model=SignOut)
async def get_sign(sign_id: int, db: DB, user: OptionalUser) -> SignOut:
    sign = await db.scalar(sign_query().where(Sign.id == sign_id, Sign.is_published.is_(True)))
    if sign is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Sign not found")

    await db.execute(update(Sign).where(Sign.id == sign_id).values(view_count=Sign.view_count + 1, updated_at=Sign.updated_at))
    is_saved = None
    if user:
        stmt = insert(RecentView).values(user_id=user.id, sign_id=sign_id)
        await db.execute(stmt.on_conflict_do_update(index_elements=["user_id", "sign_id"], set_={"viewed_at": func.now()}))
        # Keep only the latest views
        keep = (
            select(RecentView.id).where(RecentView.user_id == user.id).order_by(RecentView.viewed_at.desc()).limit(RECENT_LIMIT)
        )
        await db.execute(delete(RecentView).where(RecentView.user_id == user.id, RecentView.id.not_in(keep)))
        is_saved = bool(await db.scalar(select(SavedSign.id).where(SavedSign.user_id == user.id, SavedSign.sign_id == sign_id)))
    await db.commit()

    out = SignOut.model_validate(sign)
    return out.model_copy(
        update={
            "view_count": sign.view_count + 1,
            "related": [r for r in out.related if r.id != sign_id],
            "is_saved": is_saved,
        }
    )


# ===== saved and recent =====
@router.get("/saved-signs", response_model=list[SavedSignOut])
async def saved_signs(user: CurrentUser, db: DB) -> list[SavedSignOut]:
    rows = await db.execute(
        select(Sign, SavedSign.created_at)
        .join(SavedSign, SavedSign.sign_id == Sign.id)
        .where(SavedSign.user_id == user.id, Sign.is_published.is_(True))
        .order_by(SavedSign.created_at.desc())
    )
    return [SavedSignOut(sign=SignBrief.model_validate(s), created_at=at) for s, at in rows.all()]


@router.put("/saved-signs/{sign_id}", status_code=status.HTTP_204_NO_CONTENT)
async def save_sign(sign_id: int, user: CurrentUser, db: DB) -> Response:
    if not await db.scalar(select(Sign.id).where(Sign.id == sign_id, Sign.is_published.is_(True))):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Sign not found")
    await db.execute(insert(SavedSign).values(user_id=user.id, sign_id=sign_id).on_conflict_do_nothing())
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/saved-signs/{sign_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unsave_sign(sign_id: int, user: CurrentUser, db: DB) -> Response:
    await db.execute(delete(SavedSign).where(SavedSign.user_id == user.id, SavedSign.sign_id == sign_id))
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/recent-views", response_model=list[RecentViewOut])
async def recent_views(user: CurrentUser, db: DB) -> list[RecentViewOut]:
    rows = await db.execute(
        select(Sign, RecentView.viewed_at)
        .join(RecentView, RecentView.sign_id == Sign.id)
        .where(RecentView.user_id == user.id, Sign.is_published.is_(True))
        .order_by(RecentView.viewed_at.desc())
    )
    return [RecentViewOut(sign=SignBrief.model_validate(s), viewed_at=at) for s, at in rows.all()]


@router.delete("/recent-views", status_code=status.HTTP_204_NO_CONTENT)
async def clear_recent(user: CurrentUser, db: DB) -> Response:
    await db.execute(delete(RecentView).where(RecentView.user_id == user.id))
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== offline =====
@router.get("/offline-packages", response_model=list[OfflinePackageOut])
async def offline_packages(db: DB) -> list[OfflinePackage]:
    rows = await db.scalars(
        select(OfflinePackage).where(OfflinePackage.is_active.is_(True)).order_by(OfflinePackage.order, OfflinePackage.id)
    )
    return list(rows)

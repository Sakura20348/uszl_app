from fastapi import APIRouter, HTTPException, Query, Response, status
from sqlalchemy import delete, func, select
from sqlalchemy.orm import selectinload

from app.api.v1.app_routes.dictionary import search_filter, sign_query
from app.api.v1.common import commit, crud_routes, get_or_404
from app.deps import DB
from app.models import Category, OfflinePackage, Sign, SignCategory, SignRelated, SignVideo
from app.schemas.common import Page
from app.schemas.dictionary import (
    CategoryIn,
    CategoryOut,
    OfflinePackageIn,
    OfflinePackageOut,
    SignBrief,
    SignIn,
    SignOut,
)

router = APIRouter()
TAG = "admin: dictionary"

crud_routes(router, "/categories", Category, CategoryIn, CategoryOut, (Category.order, Category.id), TAG)
crud_routes(router, "/offline-packages", OfflinePackage, OfflinePackageIn, OfflinePackageOut, (OfflinePackage.order, OfflinePackage.id), TAG)


@router.get("/signs", response_model=Page[SignBrief], tags=[TAG])
async def list_signs(
    db: DB,
    category: str | None = Query(default=None, description="Category slug"),
    q: str | None = Query(default=None, max_length=100),
    published: bool | None = None,
    limit: int = Query(default=50, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
) -> Page[SignBrief]:
    where = []
    if category:
        where.append(Sign.categories.any(Category.slug == category))
    if q:
        where.append(search_filter(q))
    if published is not None:
        where.append(Sign.is_published.is_(published))
    total = await db.scalar(select(func.count()).select_from(Sign).where(*where)) or 0
    rows = await db.scalars(select(Sign).where(*where).order_by(Sign.id.desc()).limit(limit).offset(offset))
    return Page(items=[SignBrief.model_validate(s) for s in rows], total=total)


async def _sign_out(db: DB, sign_id: int) -> SignOut:
    db.expire_all()
    sign = await db.scalar(sign_query().where(Sign.id == sign_id))
    if sign is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Sign not found")
    return SignOut.model_validate(sign)


@router.get("/signs/{sign_id}", response_model=SignOut, tags=[TAG])
async def get_sign(sign_id: int, db: DB) -> SignOut:
    return await _sign_out(db, sign_id)


async def _save_sign(db: DB, sign: Sign, body: SignIn) -> int:
    fields = body.model_dump(exclude={"category_ids", "related_ids", "videos"})
    for field, value in fields.items():
        setattr(sign, field, value)
    db.add(sign)
    await db.flush()

    category_ids = list(dict.fromkeys(body.category_ids))
    found = set(await db.scalars(select(Category.id).where(Category.id.in_(category_ids))))
    if missing := set(category_ids) - found:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, f"Unknown category ids: {sorted(missing)}")
    related_ids = [r for r in dict.fromkeys(body.related_ids) if r != sign.id]
    found = set(await db.scalars(select(Sign.id).where(Sign.id.in_(related_ids))))
    if missing := set(related_ids) - found:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, f"Unknown related sign ids: {sorted(missing)}")
    if len({v.angle for v in body.videos}) != len(body.videos):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "One video per angle")

    # Replace the links and videos with what was sent
    await db.execute(delete(SignCategory).where(SignCategory.sign_id == sign.id))
    await db.execute(delete(SignRelated).where(SignRelated.from_sign_id == sign.id))
    await db.execute(delete(SignVideo).where(SignVideo.sign_id == sign.id))
    db.add_all(SignCategory(sign_id=sign.id, category_id=c) for c in category_ids)
    db.add_all(SignRelated(from_sign_id=sign.id, to_sign_id=r) for r in related_ids)
    db.add_all(SignVideo(sign_id=sign.id, **v.model_dump()) for v in body.videos)
    await commit(db)
    return sign.id


@router.post("/signs", response_model=SignOut, status_code=status.HTTP_201_CREATED, tags=[TAG])
async def create_sign(body: SignIn, db: DB) -> SignOut:
    return await _sign_out(db, await _save_sign(db, Sign(), body))


@router.put("/signs/{sign_id}", response_model=SignOut, tags=[TAG])
async def update_sign(sign_id: int, body: SignIn, db: DB) -> SignOut:
    sign = await db.scalar(select(Sign).where(Sign.id == sign_id).options(selectinload(Sign.videos)))
    if sign is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Sign not found")
    return await _sign_out(db, await _save_sign(db, sign, body))


@router.delete("/signs/{sign_id}", status_code=status.HTTP_204_NO_CONTENT, tags=[TAG])
async def delete_sign(sign_id: int, db: DB) -> Response:
    """Fails with 422 while a lesson or exercise still uses the sign."""
    await db.delete(await get_or_404(db, Sign, sign_id))
    await commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

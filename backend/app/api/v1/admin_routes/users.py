import uuid
from datetime import UTC, date, datetime, timedelta
from typing import Literal
from zoneinfo import ZoneInfo

from fastapi import APIRouter, BackgroundTasks, HTTPException, Query, Response, UploadFile, status
from sqlalchemy import delete, func, or_, select

from app.api.v1.common import commit, get_or_404
from app.core.config import get_settings
from app.deps import DB, Staff
from app.media import AUDIO, IMAGE, VIDEO, save_upload
from app.models import (
    ActivitySession,
    Contribution,
    Course,
    DailyActivity,
    ExerciseReport,
    Lesson,
    Notification,
    NotificationSettings,
    Sign,
    User,
    UserLessonProgress,
    UserStats,
)
from app.progress import activity_stats
from app.push import push_pending, queue_push
from app.schemas.admin import (
    ActivityDay,
    AdminUserOut,
    AdminUserUpdate,
    BroadcastIn,
    BroadcastOut,
    BroadcastStats,
    BroadcastSummary,
    PopularLesson,
    StatsOut,
)
from app.schemas.common import MediaOut, Page
from app.schemas.users import ActivityStats, Period

router = APIRouter()


# ===== home =====
@router.get("/stats", response_model=StatsOut, tags=["admin: users"])
async def stats(db: DB) -> StatsOut:
    async def count(query) -> int:
        return await db.scalar(select(func.count()).select_from(query.subquery())) or 0

    learners = select(User.id).where(User.is_staff.is_(False))
    online_since = datetime.now(UTC) - timedelta(minutes=get_settings().online_minutes)
    online = learners.where(
        or_(User.last_login >= online_since, User.id.in_(select(ActivitySession.user_id).where(ActivitySession.ended_at >= online_since)))
    )
    return StatsOut(
        learners=await count(learners),
        online=await count(online),
        new_this_week=await count(learners.where(User.date_joined >= datetime.now(UTC) - timedelta(days=7))),
        courses=await count(select(Course.id)),
        lessons=await count(select(Lesson.id)),
        signs=await count(select(Sign.id)),
        lessons_completed=await count(select(UserLessonProgress.id).where(UserLessonProgress.status == "completed")),
        pending_contributions=await count(select(Contribution.id).where(Contribution.status == "pending")),
        new_reports=await count(select(ExerciseReport.id).where(ExerciseReport.status == "new")),
    )


# The dashboard's home charts count days in Uzbekistan time
DASHBOARD_TZ = ZoneInfo("Asia/Tashkent")


@router.get("/stats/activity", response_model=list[ActivityDay], tags=["admin: users"])
async def activity_by_day(db: DB, days: int = Query(default=30, ge=1, le=365)) -> list[ActivityDay]:
    """Learners active each day, minutes learned (also per part of the app) and lessons completed, oldest day first (empty days are 0)."""
    today = datetime.now(DASHBOARD_TZ).date()
    first = today - timedelta(days=days - 1)
    learners = select(User.id).where(User.is_staff.is_(False))
    rows = await db.execute(
        select(
            DailyActivity.date,
            func.count(func.distinct(DailyActivity.user_id)).filter(
                (DailyActivity.minutes > 0) | (DailyActivity.lessons_completed > 0)
            ),
            func.coalesce(func.sum(DailyActivity.minutes), 0),
            func.coalesce(func.sum(DailyActivity.lessons_completed), 0),
        )
        .where(DailyActivity.date >= first, DailyActivity.date <= today, DailyActivity.user_id.in_(learners))
        .group_by(DailyActivity.date)
    )
    by_day = {d: (active, minutes, lessons) for d, active, minutes, lessons in rows.all()}

    # Time per part of the app, by the day the session started (Tashkent time)
    local_day = func.date(func.timezone(DASHBOARD_TZ.key, ActivitySession.started_at))
    source_rows = await db.execute(
        select(local_day, ActivitySession.source, func.sum(ActivitySession.duration_seconds))
        .where(
            ActivitySession.started_at >= datetime.combine(first, datetime.min.time(), DASHBOARD_TZ),
            ActivitySession.user_id.in_(learners),
        )
        .group_by(local_day, ActivitySession.source)
    )
    sources: dict[date, dict[str, int]] = {}
    for d, source, seconds in source_rows.all():
        sources.setdefault(d, {})[source] = int(seconds)
    out = []
    for i in range(days):
        day: date = first + timedelta(days=i)
        active, minutes, lessons = by_day.get(day, (0, 0, 0))
        out.append(ActivityDay(
            date=day, active_learners=active, minutes=minutes, lessons_completed=lessons,
            seconds_by_source=sources.get(day, {}),
        ))
    return out


@router.get("/stats/popular-lessons", response_model=list[PopularLesson], tags=["admin: users"])
async def popular_lessons(db: DB, limit: int = Query(default=5, ge=1, le=20)) -> list[PopularLesson]:
    """Lessons learners completed most (then: started most)."""
    learners = select(User.id).where(User.is_staff.is_(False))
    done = UserLessonProgress.status == "completed"
    completions = func.count().filter(done)
    rows = await db.execute(
        select(
            Lesson.id, Lesson.title, Course.id, Course.title,
            completions, func.count(), func.avg(UserLessonProgress.best_accuracy).filter(done),
        )
        .join(Lesson, Lesson.id == UserLessonProgress.lesson_id)
        .join(Course, Course.id == Lesson.course_id)
        .where(UserLessonProgress.user_id.in_(learners))
        .group_by(Lesson.id, Lesson.title, Course.id, Course.title)
        .order_by(completions.desc(), func.count().desc(), Lesson.id)
        .limit(limit)
    )
    return [
        PopularLesson(
            lesson_id=lid, lesson_title=lt, course_id=cid, course_title=ct, completions=c, learners=n,
            average_accuracy=round(avg) if avg is not None else None,
        )
        for lid, lt, cid, ct, c, n, avg in rows.all()
    ]


# ===== users =====
async def _rows(db: DB, users: list[User]) -> list[AdminUserOut]:
    ids = [u.id for u in users]
    if not ids:
        return []
    total = await db.scalar(
        select(func.count()).select_from(Lesson).join(Course).where(Lesson.is_published.is_(True), Course.is_published.is_(True))
    ) or 0
    completed = dict((await db.execute(
        select(UserLessonProgress.user_id, func.count())
        .where(UserLessonProgress.user_id.in_(ids), UserLessonProgress.status == "completed")
        .group_by(UserLessonProgress.user_id)
    )).all())
    last_session = dict((await db.execute(
        select(ActivitySession.user_id, func.max(ActivitySession.ended_at)).where(ActivitySession.user_id.in_(ids)).group_by(ActivitySession.user_id)
    )).all())
    notify = dict((await db.execute(
        select(NotificationSettings.user_id, NotificationSettings.general).where(NotificationSettings.user_id.in_(ids))
    )).all())
    stats = {s.user_id: s for s in await db.scalars(select(UserStats).where(UserStats.user_id.in_(ids)))}
    online_since = datetime.now(UTC) - timedelta(minutes=get_settings().online_minutes)

    rows = []
    for u in users:
        last = max(t for t in (u.last_login, last_session.get(u.id), u.date_joined) if t is not None)
        s = stats.get(u.id)
        rows.append(
            AdminUserOut(
                id=u.id,
                name=u.full_name or "",
                phone=u.phone or "",
                email=u.email,
                avatar=u.avatar,
                language=u.language,
                daily_goal=u.daily_goal_minutes,
                completed_lessons=completed.get(u.id, 0),
                total_lessons=total,
                source=u.referral_source,  # type: ignore[arg-type]
                reason=u.learning_goal,  # type: ignore[arg-type]
                status="online" if last >= online_since else "offline",
                notifications=notify.get(u.id, True),
                joined_at=u.date_joined,
                last_active_at=last,
                is_active=u.is_active,
                is_staff=u.is_staff,
                is_superuser=u.is_superuser,
                total_xp=s.total_xp if s else 0,
                level=s.level if s else 1,
                current_streak=s.current_streak if s else 0,
            )
        )
    return rows


@router.get("/users", response_model=Page[AdminUserOut], tags=["admin: users"])
async def list_users(
    db: DB,
    q: str | None = Query(default=None, max_length=100, description="Name, phone or email"),
    role: Literal["learners", "staff", "all"] = "learners",
    is_active: bool | None = Query(default=None, alias="isActive"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> Page[AdminUserOut]:
    where = []
    if role != "all":
        where.append(User.is_staff.is_(role == "staff"))
    if is_active is not None:
        where.append(User.is_active.is_(is_active))
    if q:
        pattern = f"%{q.strip()}%"
        where.append(or_(User.full_name.ilike(pattern), User.phone.ilike(pattern), User.email.ilike(pattern)))
    total = await db.scalar(select(func.count()).select_from(User).where(*where)) or 0
    users = list(await db.scalars(select(User).where(*where).order_by(User.date_joined.desc(), User.id.desc()).limit(limit).offset(offset)))
    return Page(items=await _rows(db, users), total=total)


@router.get("/users/{user_id}", response_model=AdminUserOut, tags=["admin: users"])
async def get_user(user_id: int, db: DB) -> AdminUserOut:
    [row] = await _rows(db, [await get_or_404(db, User, user_id, "User")])
    return row


@router.patch("/users/{user_id}", response_model=AdminUserOut, tags=["admin: users"])
async def update_user(user_id: int, body: AdminUserUpdate, admin: Staff, db: DB) -> AdminUserOut:
    user = await get_or_404(db, User, user_id, "User")
    data = body.model_dump(exclude_unset=True, exclude_none=True)
    if ("is_staff" in data or "is_superuser" in data) and not admin.is_superuser:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only a superuser can change admin rights")
    if user.id == admin.id and (data.get("is_active") is False or data.get("is_staff") is False or data.get("is_superuser") is False):
        raise HTTPException(status.HTTP_409_CONFLICT, "You can't block yourself or remove your own rights")
    if user.is_superuser and not admin.is_superuser:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only a superuser can change a superuser")
    for field, value in data.items():
        setattr(user, field, value)
    if user.is_superuser:
        user.is_staff = True
    await commit(db)
    return await get_user(user_id, db)


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["admin: users"])
async def delete_user(user_id: int, admin: Staff, db: DB) -> Response:
    user = await get_or_404(db, User, user_id, "User")
    if user.id == admin.id:
        raise HTTPException(status.HTTP_409_CONFLICT, "You can't delete yourself")
    if user.is_staff and not admin.is_superuser:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only a superuser can delete admins")
    await db.delete(user)
    await commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/users/{user_id}/activity", response_model=ActivityStats, tags=["admin: users"])
async def user_activity(user_id: int, db: DB, period: Period = "week") -> ActivityStats:
    return await activity_stats(db, await get_or_404(db, User, user_id, "User"), period)


# ===== notifications =====
# Every send stores {"broadcastId": ...} in the notifications' data, so a send can be listed and withdrawn
BROADCAST_ID = Notification.data["broadcastId"].astext


@router.post("/notifications", response_model=BroadcastOut, tags=["admin: notifications"])
async def broadcast(body: BroadcastIn, admin: Staff, db: DB, background: BackgroundTasks) -> BroadcastOut:
    """
    Adds an in-app notification for the chosen learners, or for every learner with news turned on,
    and sends it to their phones as a push notification (when FCM is set up).
    """
    learners = select(User.id).where(User.is_active.is_(True), User.is_staff.is_(False))
    if body.user_ids:
        user_ids = list(await db.scalars(learners.where(User.id.in_(body.user_ids))))
    else:
        news_off = select(NotificationSettings.user_id).where(NotificationSettings.news.is_(False))
        user_ids = list(await db.scalars(learners.where(User.id.not_in(news_off))))
    if not user_ids:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "No learners to send to")

    broadcast_id = uuid.uuid4().hex
    data = {**(body.data or {}), "broadcastId": broadcast_id, "sentBy": admin.id}
    for uid in user_ids:
        notification = Notification(user_id=uid, type=body.type, title=body.title, body=body.body, data=data)
        db.add(notification)
        queue_push(db, notification)
    await commit(db)
    push_pending(db, background)
    return BroadcastOut(id=broadcast_id, sent=len(user_ids))


@router.get("/notifications", response_model=Page[BroadcastSummary], tags=["admin: notifications"])
async def list_broadcasts(
    db: DB, limit: int = Query(default=20, ge=1, le=100), offset: int = Query(default=0, ge=0)
) -> Page[BroadcastSummary]:
    sends = (
        select(
            BROADCAST_ID.label("id"),
            func.min(Notification.type).label("type"),
            func.min(Notification.title).label("title"),
            func.min(Notification.body).label("body"),
            func.min(Notification.created_at).label("sent_at"),
            func.count().label("recipients"),
            func.count().filter(Notification.is_read.is_(True)).label("read"),
        )
        .where(BROADCAST_ID.is_not(None))
        .group_by(BROADCAST_ID)
    )
    total = await db.scalar(select(func.count()).select_from(sends.subquery())) or 0
    rows = await db.execute(sends.order_by(func.min(Notification.created_at).desc()).limit(limit).offset(offset))
    return Page(items=[BroadcastSummary.model_validate(r._mapping) for r in rows], total=total)


@router.get("/notifications/stats", response_model=BroadcastStats, tags=["admin: notifications"])
async def broadcast_stats(db: DB) -> BroadcastStats:
    row = (
        await db.execute(
            select(
                func.count(func.distinct(BROADCAST_ID)),
                func.count(),
                func.count().filter(Notification.is_read.is_(True)),
            ).where(BROADCAST_ID.is_not(None))
        )
    ).one()
    return BroadcastStats(broadcasts=row[0], delivered=row[1], read=row[2])


@router.delete("/notifications/{broadcast_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["admin: notifications"])
async def withdraw_broadcast(broadcast_id: str, db: DB) -> Response:
    """Removes a send from every learner's notifications, read or not."""
    result = await db.execute(delete(Notification).where(BROADCAST_ID == broadcast_id))
    if not result.rowcount:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Notification not found")
    await commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== uploads =====
@router.post("/media", response_model=MediaOut, status_code=status.HTTP_201_CREATED, tags=["admin: users"])
async def upload_media(file: UploadFile, folder: Literal["signs", "lessons", "courses", "dataset", "packages", "other"] = "other") -> MediaOut:
    """Sign videos, lesson images, icons. Put the returned path in the file fields."""
    allowed = VIDEO | IMAGE | AUDIO | ({"application/zip": ".zip"} if folder == "packages" else {})
    return await save_upload(file, folder, allowed)

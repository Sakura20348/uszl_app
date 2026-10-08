from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import APIRouter, BackgroundTasks, HTTPException, Query, Response, status
from sqlalchemy import func, select, update
from sqlalchemy.dialects.postgresql import insert

from app.accounts import delete_account
from app.api.v1.common import profile_out
from app.deps import DB, CurrentUser
from app.models import Achievement, Device, Notification, SocialAccount, User, UserAchievement
from app.push import push_pending
from app.progress import activity_stats, get_notification_settings, record_session, stats_out, unlock_achievements, get_stats
from app.schemas.common import Page
from app.schemas.users import (
    AchievementOut,
    ActivitySessionIn,
    ActivityStats,
    DeviceIn,
    NotificationOut,
    NotificationSettingsIO,
    NotificationSettingsUpdate,
    Period,
    ProfileOut,
    ProfileUpdate,
    UserStatsOut,
)

router = APIRouter()


# ===== profile =====
@router.get("/profile", response_model=ProfileOut)
async def get_profile(user: CurrentUser) -> ProfileOut:
    return profile_out(user)


@router.patch("/profile", response_model=ProfileOut)
async def update_profile(body: ProfileUpdate, user: CurrentUser, db: DB) -> ProfileOut:
    data = body.model_dump(exclude_unset=True)
    if "email" in data:
        email = data["email"] = data["email"].lower() if data["email"] else None
        if email and await db.scalar(select(User.id).where(User.email == email, User.id != user.id)):
            raise HTTPException(status.HTTP_409_CONFLICT, "This email is used by another account")
        has_social = await db.scalar(select(SocialAccount.id).where(SocialAccount.user_id == user.id).limit(1))
        if not email and not user.phone and not has_social:
            raise HTTPException(status.HTTP_409_CONFLICT, "Add a phone number first, or you couldn't log in")
    if "timezone" in data:
        try:
            ZoneInfo(data["timezone"] or "")
        except (ZoneInfoNotFoundError, ValueError):
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Unknown time zone, e.g. Asia/Tashkent") from None
    for field, value in data.items():
        setattr(user, field, value)
    await db.commit()
    await db.refresh(user)
    return profile_out(user)


@router.delete("/profile", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account_(user: CurrentUser, db: DB) -> Response:
    await delete_account(db, user)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/notification-settings", response_model=NotificationSettingsIO)
async def get_settings_(user: CurrentUser, db: DB):
    settings = await get_notification_settings(db, user.id)
    await db.commit()
    return settings


@router.patch("/notification-settings", response_model=NotificationSettingsIO)
async def update_settings(body: NotificationSettingsUpdate, user: CurrentUser, db: DB):
    settings = await get_notification_settings(db, user.id)
    for field, value in body.model_dump(exclude_unset=True, exclude_none=True).items():
        setattr(settings, field, value)
    await db.commit()
    return settings


# ===== push notification devices =====
@router.post("/devices", status_code=status.HTTP_204_NO_CONTENT)
async def register_device(body: DeviceIn, user: CurrentUser, db: DB) -> Response:
    # A token moves to whoever logged in on that phone last
    stmt = insert(Device).values(user_id=user.id, token=body.token, platform=body.platform)
    await db.execute(
        stmt.on_conflict_do_update(
            index_elements=["token"],
            set_={"user_id": user.id, "platform": body.platform, "is_active": True, "last_seen_at": func.now()},
        )
    )
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/devices/{token}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_device(token: str, user: CurrentUser, db: DB) -> Response:
    await db.execute(update(Device).where(Device.token == token, Device.user_id == user.id).values(is_active=False))
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== stats and activity =====
@router.get("/stats", response_model=UserStatsOut)
async def my_stats(user: CurrentUser, db: DB) -> UserStatsOut:
    out = await stats_out(db, user)
    await db.commit()
    return out


@router.get("/activity", response_model=ActivityStats)
async def my_activity(user: CurrentUser, db: DB, period: Period = "week") -> ActivityStats:
    return await activity_stats(db, user, period)


@router.post("/presence/offline", status_code=status.HTTP_204_NO_CONTENT)
async def go_offline(user: CurrentUser, db: DB) -> Response:
    """The app was closed or logged out: the dashboard shows the user offline right away."""
    user.offline_at = datetime.now(UTC)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/activity-sessions", status_code=status.HTTP_204_NO_CONTENT)
async def report_session(body: ActivitySessionIn, user: CurrentUser, db: DB, background: BackgroundTasks) -> Response:
    """Time spent outside lessons (lessons are recorded when they finish)."""
    started = body.started_at if body.started_at.tzinfo else body.started_at.replace(tzinfo=UTC)
    ended = body.ended_at if body.ended_at.tzinfo else body.ended_at.replace(tzinfo=UTC)
    if ended <= started:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "endedAt must be after startedAt")
    if ended > datetime.now(UTC) + timedelta(minutes=5):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "endedAt is in the future")
    await record_session(db, user, body.source, started, ended)
    # A longer streak may unlock an achievement
    await unlock_achievements(db, user, await get_stats(db, user.id))
    await db.commit()
    push_pending(db, background)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== achievements =====
@router.get("/achievements", response_model=list[AchievementOut])
async def my_achievements(user: CurrentUser, db: DB) -> list[AchievementOut]:
    rows = await db.execute(
        select(Achievement, UserAchievement.unlocked_at)
        .outerjoin(
            UserAchievement,
            (UserAchievement.achievement_id == Achievement.id) & (UserAchievement.user_id == user.id),
        )
        .order_by(Achievement.order, Achievement.id)
    )
    return [AchievementOut.model_validate(a).model_copy(update={"unlocked_at": at}) for a, at in rows.all()]


# ===== notifications =====
@router.get("/notifications", response_model=Page[NotificationOut])
async def my_notifications(
    user: CurrentUser,
    db: DB,
    unread: bool = False,
    limit: int = Query(default=30, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> Page[NotificationOut]:
    where = [Notification.user_id == user.id]
    if unread:
        where.append(Notification.is_read.is_(False))
    total = await db.scalar(select(func.count()).where(*where)) or 0
    rows = await db.scalars(
        select(Notification).where(*where).order_by(Notification.created_at.desc(), Notification.id.desc()).limit(limit).offset(offset)
    )
    return Page(items=[NotificationOut.model_validate(n) for n in rows], total=total)


@router.post("/notifications/{notification_id}/read", status_code=status.HTTP_204_NO_CONTENT)
async def read_notification(notification_id: int, user: CurrentUser, db: DB) -> Response:
    await db.execute(
        update(Notification).where(Notification.id == notification_id, Notification.user_id == user.id).values(is_read=True)
    )
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/notifications/read-all", status_code=status.HTTP_204_NO_CONTENT)
async def read_all(user: CurrentUser, db: DB) -> Response:
    await db.execute(update(Notification).where(Notification.user_id == user.id).values(is_read=True))
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)

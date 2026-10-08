"""XP, levels, streaks, daily activity, achievements and the activity charts."""

import calendar
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.models import (
    Achievement,
    ActivitySession,
    DailyActivity,
    LearnedSign,
    Lesson,
    LessonSign,
    Notification,
    NotificationSettings,
    User,
    UserAchievement,
    UserLessonProgress,
    UserStats,
)
from app.push import queue_push
from app.schemas.users import ActivityBar, ActivityStats, BarLabel, Period, UserStatsOut

WEEKDAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
# Rows of the activity calendar, top to bottom: the hour each slot starts at
SLOT_HOURS = [22, 19, 16, 13, 10, 7, 4, 0]
# Longest session we accept, so an attempt left open overnight doesn't count as hours of learning
MAX_SESSION_SECONDS = 2 * 60 * 60

# Lessons finished from this hour (local time) until NIGHT_ENDS count as "night" lessons
NIGHT_STARTS, NIGHT_ENDS = 22, 4


def user_tz(user: User) -> ZoneInfo:
    try:
        return ZoneInfo(user.timezone)
    except (ZoneInfoNotFoundError, ValueError):
        return ZoneInfo("Asia/Tashkent")


def level_for(xp: int) -> int:
    return xp // get_settings().xp_per_level + 1


async def get_stats(db: AsyncSession, user_id: int) -> UserStats:
    stats = await db.get(UserStats, user_id)
    if stats is None:
        await db.execute(insert(UserStats).values(user_id=user_id).on_conflict_do_nothing())
        stats = await db.get(UserStats, user_id)
    assert stats is not None
    return stats


async def get_notification_settings(db: AsyncSession, user_id: int) -> NotificationSettings:
    settings = await db.scalar(select(NotificationSettings).where(NotificationSettings.user_id == user_id))
    if settings is None:
        await db.execute(insert(NotificationSettings).values(user_id=user_id).on_conflict_do_nothing())
        settings = await db.scalar(select(NotificationSettings).where(NotificationSettings.user_id == user_id))
    assert settings is not None
    return settings


async def add_daily(db: AsyncSession, user_id: int, day: date, **increments: int) -> None:
    """Adds to today's row in daily_activities (creates it if needed)."""
    values = {k: v for k, v in increments.items() if v}
    if not values:
        return
    stmt = insert(DailyActivity).values(user_id=user_id, date=day, **values)
    stmt = stmt.on_conflict_do_update(
        index_elements=["user_id", "date"],
        set_={k: getattr(DailyActivity, k) + getattr(stmt.excluded, k) for k in values},
    )
    await db.execute(stmt)


async def update_streak(db: AsyncSession, stats: UserStats) -> None:
    """Recounts the streak from daily_activities, so sessions synced late (e.g. after offline use) still count."""
    days = sorted(set(await db.scalars(select(DailyActivity.date).where(DailyActivity.user_id == stats.user_id))))
    if not days:
        return
    longest = run = 1
    for previous, day in zip(days, days[1:]):
        run = run + 1 if day - previous == timedelta(days=1) else 1
        longest = max(longest, run)
    # `run` is now the streak ending on the latest active day
    stats.current_streak = run
    stats.longest_streak = max(stats.longest_streak, longest)
    stats.last_active_date = days[-1]


async def record_session(
    db: AsyncSession, user: User, source: str, started_at: datetime, ended_at: datetime
) -> ActivitySession:
    seconds = min(int((ended_at - started_at).total_seconds()), MAX_SESSION_SECONDS)
    session = ActivitySession(
        user_id=user.id, source=source, started_at=started_at, ended_at=ended_at, duration_seconds=max(seconds, 0)
    )
    db.add(session)
    day = started_at.astimezone(user_tz(user)).date()
    # The row is created even for a short session, so the day counts for the streak
    await add_daily(db, user.id, day, minutes=round(seconds / 60))
    await db.execute(insert(DailyActivity).values(user_id=user.id, date=day).on_conflict_do_nothing())
    await update_streak(db, await get_stats(db, user.id))
    return session


async def lessons_completed(db: AsyncSession, user_id: int) -> int:
    return await db.scalar(
        select(func.count()).where(UserLessonProgress.user_id == user_id, UserLessonProgress.status == "completed")
    ) or 0


async def learn_lesson_signs(db: AsyncSession, user_id: int, lesson_id: int) -> int:
    """Marks the lesson's signs as learned; returns the user's new learned-sign total."""
    sign_ids = list(await db.scalars(select(LessonSign.sign_id).where(LessonSign.lesson_id == lesson_id)))
    if sign_ids:
        await db.execute(
            insert(LearnedSign)
            .values([{"user_id": user_id, "sign_id": s} for s in sign_ids])
            .on_conflict_do_nothing(index_elements=["user_id", "sign_id"])
        )
    return await db.scalar(select(func.count()).where(LearnedSign.user_id == user_id)) or 0


async def _condition_met(db: AsyncSession, user_id: int, stats: UserStats, a: Achievement, completed: int) -> bool:
    match a.condition_type:
        case "lessons_completed":
            return completed >= a.condition_value
        case "signs_learned":
            return stats.signs_learned >= a.condition_value
        case "streak_days":
            return stats.current_streak >= a.condition_value
        case "total_xp":
            return stats.total_xp >= a.condition_value
        case "perfect_lessons":
            perfect = await db.scalar(
                select(func.count()).where(UserLessonProgress.user_id == user_id, UserLessonProgress.best_accuracy == 100)
            ) or 0
            return perfect >= a.condition_value
        case "goal_days":
            goal = select(User.daily_goal_minutes).where(User.id == user_id).scalar_subquery()
            days = await db.scalar(
                select(func.count()).where(DailyActivity.user_id == user_id, DailyActivity.minutes >= goal)
            ) or 0
            return days >= a.condition_value
        case "night_lessons":
            tz = await db.scalar(select(User.timezone).where(User.id == user_id))
            hour = func.extract("hour", func.timezone(tz, ActivitySession.ended_at))
            nights = await db.scalar(
                select(func.count()).where(
                    ActivitySession.user_id == user_id,
                    ActivitySession.source == "lesson",
                    (hour >= NIGHT_STARTS) | (hour < NIGHT_ENDS),
                )
            ) or 0
            return nights >= a.condition_value
        case "course_signs_learned":
            if a.course_id is None:
                return False
            course_signs = select(LessonSign.sign_id).join(Lesson).where(Lesson.course_id == a.course_id)
            learned = await db.scalar(
                select(func.count()).where(LearnedSign.user_id == user_id, LearnedSign.sign_id.in_(course_signs))
            ) or 0
            return learned >= a.condition_value
        case "course_completed":
            if a.course_id is None:
                return False
            lessons = select(Lesson.id).where(Lesson.course_id == a.course_id, Lesson.is_published.is_(True))
            total = await db.scalar(select(func.count()).select_from(lessons.subquery())) or 0
            done = await db.scalar(
                select(func.count()).where(
                    UserLessonProgress.user_id == user_id,
                    UserLessonProgress.status == "completed",
                    UserLessonProgress.lesson_id.in_(lessons),
                )
            ) or 0
            return total > 0 and done >= total
    return False


async def unlock_achievements(db: AsyncSession, user: User, stats: UserStats) -> list[tuple[Achievement, datetime]]:
    """Unlocks every achievement the user now qualifies for; adds their XP and a notification."""
    owned = select(UserAchievement.achievement_id).where(UserAchievement.user_id == user.id)
    candidates = list(await db.scalars(select(Achievement).where(Achievement.id.not_in(owned)).order_by(Achievement.order)))
    completed = await lessons_completed(db, user.id)
    notify = (await get_notification_settings(db, user.id)).new_achievements
    unlocked = []
    now = datetime.now(UTC)
    for a in candidates:
        if not await _condition_met(db, user.id, stats, a, completed):
            continue
        db.add(UserAchievement(user_id=user.id, achievement_id=a.id, unlocked_at=now))
        stats.total_xp += a.xp_reward
        if notify:
            notification = Notification(
                user_id=user.id, type="achievement", title=a.title, body=a.description or "",
                data={"achievementId": a.id, "code": a.code},
            )
            db.add(notification)
            queue_push(db, notification)
        unlocked.append((a, now))
    stats.level = level_for(stats.total_xp)
    return unlocked


async def stats_out(db: AsyncSession, user: User) -> UserStatsOut:
    stats = await get_stats(db, user.id)
    today = datetime.now(user_tz(user)).date()
    today_row = await db.scalar(select(DailyActivity).where(DailyActivity.user_id == user.id, DailyActivity.date == today))
    correct_all, total_all = (
        await db.execute(
            select(func.coalesce(func.sum(DailyActivity.correct_answers), 0), func.coalesce(func.sum(DailyActivity.total_answers), 0))
            .where(DailyActivity.user_id == user.id)
        )
    ).one()
    monday = today - timedelta(days=today.weekday())
    active_days = set(
        await db.scalars(select(DailyActivity.date).where(DailyActivity.user_id == user.id, DailyActivity.date >= monday))
    )

    def percent(part: int, whole: int) -> int | None:
        return round(part * 100 / whole) if whole else None

    per_level = get_settings().xp_per_level
    # A streak only counts if the user was active today or yesterday
    streak = stats.current_streak if stats.last_active_date and today - stats.last_active_date <= timedelta(days=1) else 0
    return UserStatsOut(
        total_xp=stats.total_xp,
        level=stats.level,
        xp_to_next_level=per_level - stats.total_xp % per_level,
        current_streak=streak,
        longest_streak=stats.longest_streak,
        last_active_date=stats.last_active_date,
        signs_learned=stats.signs_learned,
        lessons_completed=await lessons_completed(db, user.id),
        today_minutes=today_row.minutes if today_row else 0,
        daily_goal_minutes=user.daily_goal_minutes,
        lessons_today=today_row.lessons_completed if today_row else 0,
        xp_today=today_row.xp if today_row else 0,
        accuracy=percent(correct_all, total_all),
        accuracy_today=percent(today_row.correct_answers, today_row.total_answers) if today_row else None,
        week_days=[(monday + timedelta(days=i)) in active_days for i in range(7)],
    )


async def last_active_at(db: AsyncSession, user: User) -> datetime:
    """Latest of: login, end of an activity session."""
    last_session = await db.scalar(select(func.max(ActivitySession.ended_at)).where(ActivitySession.user_id == user.id))
    return max(t for t in (user.last_login, last_session, user.date_joined) if t is not None)


def is_online(last_active: datetime) -> bool:
    return datetime.now(UTC) - last_active < timedelta(minutes=get_settings().online_minutes)


# ===== activity charts =====
def _slot_row(hour: int) -> int:
    return next(i for i, start in enumerate(SLOT_HOURS) if hour >= start)


async def activity_stats(db: AsyncSession, user: User, period: Period) -> ActivityStats:
    tz = user_tz(user)
    today = datetime.now(tz).date()

    if period == "week":
        start = today - timedelta(days=today.weekday())
        weeks = 1
        heat_from = start
    elif period == "month":
        start = today - timedelta(days=27)
        weeks = 4
        heat_from = start
    else:
        weeks = 52
        heat_from = today - timedelta(weeks=52) + timedelta(days=1)
        start = min(date(today.year, 1, 1), heat_from)

    days = dict(
        (
            await db.execute(
                select(DailyActivity.date, DailyActivity.minutes).where(
                    DailyActivity.user_id == user.id, DailyActivity.date >= start
                )
            )
        ).all()
    )
    sessions = (
        await db.execute(
            select(ActivitySession.started_at, ActivitySession.duration_seconds).where(
                ActivitySession.user_id == user.id,
                ActivitySession.started_at >= datetime.combine(heat_from, time.min, tz),
            )
        )
    ).all()

    heatmap = [[0] * 7 for _ in SLOT_HOURS]
    for started, seconds in sessions:
        local = started.astimezone(tz)
        heatmap[_slot_row(local.hour)][local.weekday()] += round(seconds / 60)

    def per_day(first: date, count: int) -> int:
        return round(sum(days.get(first + timedelta(days=i), 0) for i in range(count)) / count)

    if period == "week":
        bars = [
            ActivityBar(key=d, label=BarLabel(key=f"days.{d}"), minutes=per_day(start + timedelta(days=i), 1))
            for i, d in enumerate(WEEKDAYS)
        ]
    elif period == "month":
        bars = [
            ActivityBar(key=f"w{i + 1}", label=BarLabel(key="weekN", n=i + 1), minutes=per_day(start + timedelta(weeks=i), 7))
            for i in range(4)
        ]
    else:
        bars = [
            ActivityBar(
                key=f"m{m}",
                label=BarLabel(key=f"months.m{m}"),
                minutes=per_day(date(today.year, m, 1), calendar.monthrange(today.year, m)[1]),
            )
            for m in range(1, 13)
        ]
    return ActivityStats(bars=bars, heatmap=heatmap, weeks=weeks)

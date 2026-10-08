from datetime import date, datetime
from typing import Literal

from pydantic import EmailStr, Field

from app.schemas.common import LanguageCode, MediaPath, Schema

Proficiency = Literal["beginner", "intermediate", "advanced"]
LearningGoal = Literal["work", "education", "hearing", "communication", "curiosity"]
ReferralSource = Literal["bloggers", "google", "appStore", "googlePlay", "youtube", "instagram", "telegram", "other"]
DailyGoal = Literal[5, 10, 15, 20]
Period = Literal["week", "month", "year"]
ActivitySource = Literal["lesson", "dictionary", "translator", "dataset", "other"]


class ProfileOut(Schema):
    id: int
    phone: str | None
    email: str | None
    full_name: str | None
    avatar: MediaPath
    language: LanguageCode
    proficiency: Proficiency
    timezone: str
    learning_goal: LearningGoal | None
    referral_source: ReferralSource | None
    daily_goal_minutes: int
    onboarding_completed: bool
    has_password: bool
    is_staff: bool
    is_superuser: bool
    date_joined: datetime


class ProfileUpdate(Schema):
    # null removes it (only if the account can still log in another way)
    email: EmailStr | None = None
    full_name: str | None = Field(default=None, max_length=150)
    avatar: str | None = Field(default=None, max_length=100)
    language: LanguageCode | None = None
    proficiency: Proficiency | None = None
    timezone: str | None = Field(default=None, max_length=64)
    learning_goal: LearningGoal | None = None
    referral_source: ReferralSource | None = None
    daily_goal_minutes: DailyGoal | None = None
    onboarding_completed: bool | None = None


class NotificationSettingsIO(Schema):
    general: bool = True
    daily_reminders: bool = True
    goal_reminders: bool = False
    new_achievements: bool = True
    news: bool = True
    activity_reminders: bool = False


class NotificationSettingsUpdate(Schema):
    general: bool | None = None
    daily_reminders: bool | None = None
    goal_reminders: bool | None = None
    new_achievements: bool | None = None
    news: bool | None = None
    activity_reminders: bool | None = None


class DeviceIn(Schema):
    token: str = Field(min_length=1, max_length=255)
    platform: Literal["android", "ios", "web"]


class UserStatsOut(Schema):
    total_xp: int = 0
    level: int = 1
    # XP still needed for the next level
    xp_to_next_level: int = 0
    current_streak: int = 0
    longest_streak: int = 0
    last_active_date: date | None = None
    signs_learned: int = 0
    lessons_completed: int = 0
    # Minutes learned today and the daily goal
    today_minutes: int = 0
    daily_goal_minutes: int = 10
    # Today only
    lessons_today: int = 0
    xp_today: int = 0
    # Share of right answers (0-100), overall and today; null before the first answer
    accuracy: int | None = None
    accuracy_today: int | None = None
    # Days of this week (Monday first) with any learning
    week_days: list[bool] = [False] * 7


class ActivitySessionIn(Schema):
    source: ActivitySource
    started_at: datetime
    ended_at: datetime


class BarLabel(Schema):
    key: str
    n: int | None = None


class ActivityBar(Schema):
    key: str
    label: BarLabel
    # Average learning minutes per day
    minutes: int


class ActivityStats(Schema):
    bars: list[ActivityBar]
    # Minutes per time slot (rows, 22:00 at the top) and weekday (columns, Monday first)
    heatmap: list[list[int]]
    weeks: int


class AchievementOut(Schema):
    id: int
    code: str
    title: str
    description: str | None
    why_it_matters: str | None
    icon: MediaPath
    condition_type: str
    condition_value: int
    course_id: int | None
    xp_reward: int
    order: int
    unlocked_at: datetime | None = None


class NotificationOut(Schema):
    id: int
    type: str
    title: str
    body: str
    data: dict | list | None
    is_read: bool
    created_at: datetime

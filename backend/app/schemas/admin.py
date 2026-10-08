from datetime import date, datetime
from typing import Literal

from pydantic import Field

from app.schemas.common import MediaPath, Schema
from app.schemas.users import LearningGoal, ReferralSource


class AdminUserOut(Schema):
    """A row on the dashboard's Users page."""

    id: int
    name: str
    phone: str
    email: str | None
    # Profile photo URL ("/media/...")
    avatar: MediaPath = None
    language: str
    daily_goal: int
    completed_lessons: int
    total_lessons: int
    source: ReferralSource | None
    reason: LearningGoal | None
    status: Literal["online", "offline"]
    notifications: bool
    joined_at: datetime
    last_active_at: datetime
    is_active: bool
    is_staff: bool
    is_superuser: bool
    total_xp: int
    level: int
    current_streak: int


class AdminUserUpdate(Schema):
    # Block / unblock
    is_active: bool | None = None
    # Only a superuser can change these two
    is_staff: bool | None = None
    is_superuser: bool | None = None


class StatsOut(Schema):
    learners: int
    online: int
    new_this_week: int
    courses: int
    lessons: int
    signs: int
    lessons_completed: int
    pending_contributions: int
    new_reports: int


class BroadcastIn(Schema):
    type: Literal["news", "reminder", "system"] = "news"
    title: str = Field(min_length=1, max_length=150)
    body: str = Field(min_length=1, max_length=4000)
    data: dict | None = None
    # Empty = everyone who has news notifications on
    user_ids: list[int] | None = None


class BroadcastOut(Schema):
    # Id of this send, to find or withdraw it later
    id: str
    sent: int


class BroadcastSummary(Schema):
    """One send on the dashboard's Notifications page."""

    id: str
    type: str
    title: str
    body: str
    sent_at: datetime
    # Learners who got it, and how many of them opened it
    recipients: int
    read: int


class BroadcastStats(Schema):
    broadcasts: int
    delivered: int
    read: int


class ReportUpdate(Schema):
    status: Literal["new", "reviewed", "fixed", "rejected"]


class AchievementIn(Schema):
    code: str = Field(min_length=1, max_length=50, pattern=r"^[a-z0-9_]+$")
    title: str = Field(min_length=1, max_length=100)
    description: str | None = Field(default=None, max_length=255)
    why_it_matters: str | None = None
    icon: str | None = Field(default=None, max_length=100)
    # course_completed and course_signs_learned also need course_id
    condition_type: Literal[
        "lessons_completed", "perfect_lessons", "signs_learned", "streak_days", "goal_days",
        "night_lessons", "total_xp", "course_completed", "course_signs_learned",
    ]
    condition_value: int = Field(ge=0)
    course_id: int | None = None
    xp_reward: int = Field(default=0, ge=0)
    order: int = 0


class AdminReportOut(Schema):
    """A learner's report about an exercise, with what the dashboard needs to find and fix it."""

    id: int
    exercise_id: int
    # wrong_answer | bad_video | typo | other
    reason: str
    comment: str | None
    # new | reviewed | fixed | rejected
    status: str
    created_at: datetime
    exercise_type: str
    exercise_prompt: str | None
    lesson_id: int
    lesson_title: str
    course_id: int
    course_title: str
    user_id: int | None
    user_name: str | None


class ActivityDay(Schema):
    """One day on the dashboard's Learner activity chart."""

    date: date
    # Learners who learned that day (minutes or a finished lesson)
    active_learners: int
    minutes: int
    lessons_completed: int
    # Seconds spent in each part of the app: lesson, dictionary, translator, dataset, other
    seconds_by_source: dict[str, int] = {}


class PopularLesson(Schema):
    lesson_id: int
    lesson_title: str
    course_id: int
    course_title: str
    # Learners who completed it / started it
    completions: int
    learners: int
    # Average best score (0-100) of those who completed it
    average_accuracy: int | None

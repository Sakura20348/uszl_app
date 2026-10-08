"""Tables from the UzSL database diagram (backend/schema.sql).

Differences from the exported SQL, on purpose:
- users.id is BIGINT like every column that references it (the diagram has INTEGER).
- notification_settings.user_id and user_stats.user_id reference users.id; the diagram had
  these two references reversed (users.id -> them), which would block creating users.
- courses.unit_label defaults to so'z (the exported SQL has an unescaped quote).
- Timestamps are TIMESTAMPTZ so times stay correct across time zones.
- users.email (unique, optional) is added for email + password login.
"""

from datetime import date, datetime
from typing import Any

from sqlalchemy import (
    BigInteger,
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    Integer,
    SmallInteger,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


def _pk() -> Mapped[int]:
    return mapped_column(BigInteger, Identity(), primary_key=True)


def _fk(target: str, ondelete: str, nullable: bool = False) -> Mapped[Any]:
    return mapped_column(BigInteger, ForeignKey(target, ondelete=ondelete), nullable=nullable)


def _now() -> Mapped[datetime]:
    return mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


def _flag(default: bool) -> Mapped[bool]:
    return mapped_column(Boolean, default=default, server_default="true" if default else "false", nullable=False)


def _int(default: int = 0, small: bool = False) -> Mapped[int]:
    return mapped_column(SmallInteger if small else Integer, default=default, server_default=str(default), nullable=False)


def _str(length: int, default: str) -> Mapped[str]:
    return mapped_column(String(length), default=default, server_default=default, nullable=False)


# ============================== users and auth ==============================
class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = _pk()
    # "+998901234567"
    phone: Mapped[str | None] = mapped_column(String(20), unique=True)
    # Lowercase. Not in the diagram: added so people can log in with email + password
    email: Mapped[str | None] = mapped_column(String(254), unique=True)
    # Password hash; empty for accounts that only log in with SMS codes or Google/Apple
    password: Mapped[str | None] = mapped_column(String(128))
    full_name: Mapped[str | None] = mapped_column(String(150))
    # Path under /media
    avatar: Mapped[str | None] = mapped_column(String(100))
    language: Mapped[str] = _str(2, "uz")
    # beginner | intermediate | advanced
    proficiency: Mapped[str] = _str(20, "beginner")
    timezone: Mapped[str] = _str(64, "Asia/Tashkent")
    # Onboarding answers: why they learn, where they heard about the app
    learning_goal: Mapped[str | None] = mapped_column(String(20))
    referral_source: Mapped[str | None] = mapped_column(String(20))
    daily_goal_minutes: Mapped[int] = _int(10, small=True)
    onboarding_completed: Mapped[bool] = _flag(False)
    is_active: Mapped[bool] = _flag(True)
    # Can use the admin dashboard
    is_staff: Mapped[bool] = _flag(False)
    # Can also manage other admins
    is_superuser: Mapped[bool] = _flag(False)
    last_login: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    date_joined: Mapped[datetime] = _now()

    notification_settings: Mapped["NotificationSettings | None"] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True
    )
    stats: Mapped["UserStats | None"] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True
    )


class SocialAccount(Base):
    __tablename__ = "social_accounts"
    __table_args__ = (
        Index(None, "provider", "uid", unique=True),
        Index(None, "user_id", "provider", unique=True),
    )

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    # google | apple
    provider: Mapped[str] = mapped_column(String(10))
    # The provider's user id ("sub" in the ID token)
    uid: Mapped[str] = mapped_column(String(255))
    email: Mapped[str | None] = mapped_column(String(254))
    created_at: Mapped[datetime] = _now()


class PhoneOtp(Base):
    """SMS code; only its hash is stored."""

    __tablename__ = "phone_otps"

    id: Mapped[int] = _pk()
    phone: Mapped[str] = mapped_column(String(20), index=True)
    # login | reset_password
    purpose: Mapped[str] = mapped_column(String(20))
    code_hash: Mapped[str] = mapped_column(String(64))
    attempts: Mapped[int] = _int(0, small=True)
    is_used: Mapped[bool] = _flag(False)
    created_at: Mapped[datetime] = _now()
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class NotificationSettings(Base):
    __tablename__ = "notification_settings"

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    general: Mapped[bool] = _flag(True)
    daily_reminders: Mapped[bool] = _flag(True)
    goal_reminders: Mapped[bool] = _flag(False)
    new_achievements: Mapped[bool] = _flag(True)
    news: Mapped[bool] = _flag(True)
    activity_reminders: Mapped[bool] = _flag(False)

    user: Mapped[User] = relationship(back_populates="notification_settings")


class Device(Base):
    """Push notification token of a phone."""

    __tablename__ = "devices"

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    token: Mapped[str] = mapped_column(String(255), unique=True)
    # android | ios | web
    platform: Mapped[str] = mapped_column(String(10))
    is_active: Mapped[bool] = _flag(True)
    created_at: Mapped[datetime] = _now()
    last_seen_at: Mapped[datetime] = _now()


# ============================== dictionary ==============================
class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = _pk()
    name: Mapped[str] = mapped_column(String(100))
    name_ru: Mapped[str | None] = mapped_column(String(100))
    name_en: Mapped[str | None] = mapped_column(String(100))
    slug: Mapped[str] = mapped_column(String(100), unique=True)
    description: Mapped[str | None] = mapped_column(String(255))
    icon: Mapped[str | None] = mapped_column(String(100))
    unit_label: Mapped[str] = _str(30, "imo-ishora")
    is_emergency: Mapped[bool] = _flag(False)
    is_featured: Mapped[bool] = _flag(False)
    order: Mapped[int] = _int(0)


class SignCategory(Base):
    __tablename__ = "sign_categories"
    __table_args__ = (Index(None, "sign_id", "category_id", unique=True),)

    id: Mapped[int] = _pk()
    sign_id: Mapped[int] = _fk("signs.id", "CASCADE")
    category_id: Mapped[int] = _fk("categories.id", "CASCADE")


class SignRelated(Base):
    __tablename__ = "sign_related"
    __table_args__ = (Index(None, "from_sign_id", "to_sign_id", unique=True),)

    id: Mapped[int] = _pk()
    from_sign_id: Mapped[int] = _fk("signs.id", "CASCADE")
    to_sign_id: Mapped[int] = _fk("signs.id", "CASCADE")


class Sign(Base):
    __tablename__ = "signs"

    id: Mapped[int] = _pk()
    # Uzbek word
    word: Mapped[str] = mapped_column(String(255), index=True)
    # Syllables, e.g. "ol-ma"
    transcription: Mapped[str | None] = mapped_column(String(255))
    transcription_ru: Mapped[str | None] = mapped_column(String(255))
    transcription_en: Mapped[str | None] = mapped_column(String(255))
    translation_ru: Mapped[str | None] = mapped_column(String(255))
    translation_en: Mapped[str | None] = mapped_column(String(255))
    # word | letter | number | phrase
    kind: Mapped[str] = _str(10, "word")
    thumbnail: Mapped[str | None] = mapped_column(String(100))
    meaning: Mapped[str | None] = mapped_column(Text)
    meaning_ru: Mapped[str | None] = mapped_column(Text)
    meaning_en: Mapped[str | None] = mapped_column(Text)
    hand_shape: Mapped[str | None] = mapped_column(Text)
    hand_shape_ru: Mapped[str | None] = mapped_column(Text)
    hand_shape_en: Mapped[str | None] = mapped_column(Text)
    movement: Mapped[str | None] = mapped_column(Text)
    movement_ru: Mapped[str | None] = mapped_column(Text)
    movement_en: Mapped[str | None] = mapped_column(Text)
    example_sentence: Mapped[str | None] = mapped_column(String(500))
    example_sentence_ru: Mapped[str | None] = mapped_column(String(500))
    example_sentence_en: Mapped[str | None] = mapped_column(String(500))
    example_video: Mapped[str | None] = mapped_column(String(100))
    is_published: Mapped[bool] = _flag(True)
    view_count: Mapped[int] = _int(0)
    created_at: Mapped[datetime] = _now()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    videos: Mapped[list["SignVideo"]] = relationship(
        order_by="SignVideo.order", cascade="all, delete-orphan", passive_deletes=True
    )
    categories: Mapped[list[Category]] = relationship(secondary="sign_categories", order_by=Category.order)
    related: Mapped[list["Sign"]] = relationship(
        secondary="sign_related",
        primaryjoin="Sign.id == SignRelated.from_sign_id",
        secondaryjoin="Sign.id == SignRelated.to_sign_id",
    )


class SignVideo(Base):
    __tablename__ = "sign_videos"
    __table_args__ = (Index(None, "sign_id", "angle", unique=True),)

    id: Mapped[int] = _pk()
    sign_id: Mapped[int] = _fk("signs.id", "CASCADE")
    video: Mapped[str] = mapped_column(String(100))
    # front | side | ...
    angle: Mapped[str] = _str(10, "front")
    duration_ms: Mapped[int | None] = mapped_column(Integer)
    order: Mapped[int] = _int(0, small=True)


class SavedSign(Base):
    __tablename__ = "saved_signs"
    __table_args__ = (Index(None, "user_id", "sign_id", unique=True),)

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    sign_id: Mapped[int] = _fk("signs.id", "CASCADE")
    created_at: Mapped[datetime] = _now()


class RecentView(Base):
    __tablename__ = "recent_views"
    __table_args__ = (Index(None, "user_id", "sign_id", unique=True),)

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    sign_id: Mapped[int] = _fk("signs.id", "CASCADE")
    viewed_at: Mapped[datetime] = _now()


class OfflinePackage(Base):
    """Downloadable bundle of videos for offline use."""

    __tablename__ = "offline_packages"

    id: Mapped[int] = _pk()
    slug: Mapped[str] = mapped_column(String(50), unique=True)
    title: Mapped[str] = mapped_column(String(100))
    file: Mapped[str] = mapped_column(String(100))
    size_bytes: Mapped[int] = mapped_column(BigInteger, default=0, server_default="0")
    version: Mapped[int] = _int(1)
    is_active: Mapped[bool] = _flag(True)
    order: Mapped[int] = _int(0, small=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


# ============================== courses and lessons ==============================
class Course(Base):
    __tablename__ = "courses"

    id: Mapped[int] = _pk()
    title: Mapped[str] = mapped_column(String(100))
    title_ru: Mapped[str | None] = mapped_column(String(100))
    title_en: Mapped[str | None] = mapped_column(String(100))
    slug: Mapped[str] = mapped_column(String(100), unique=True)
    subtitle: Mapped[str | None] = mapped_column(String(255))
    subtitle_ru: Mapped[str | None] = mapped_column(String(255))
    subtitle_en: Mapped[str | None] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(String(255))
    description_ru: Mapped[str | None] = mapped_column(String(255))
    description_en: Mapped[str | None] = mapped_column(String(255))
    icon: Mapped[str | None] = mapped_column(String(100))
    unit_label: Mapped[str] = mapped_column(String(30), default="so'z", server_default="so'z")
    order: Mapped[int] = _int(0)
    is_published: Mapped[bool] = _flag(True)

    lessons: Mapped[list["Lesson"]] = relationship(
        back_populates="course", order_by="Lesson.order", cascade="all, delete-orphan", passive_deletes=True
    )


class Lesson(Base):
    __tablename__ = "lessons"

    id: Mapped[int] = _pk()
    course_id: Mapped[int] = _fk("courses.id", "CASCADE")
    title: Mapped[str] = mapped_column(String(150))
    title_ru: Mapped[str | None] = mapped_column(String(150))
    title_en: Mapped[str | None] = mapped_column(String(150))
    description: Mapped[str | None] = mapped_column(Text)
    description_ru: Mapped[str | None] = mapped_column(Text)
    description_en: Mapped[str | None] = mapped_column(Text)
    thumbnail: Mapped[str | None] = mapped_column(String(100))
    duration_minutes: Mapped[int] = _int(5, small=True)
    # easy | medium | hard
    difficulty: Mapped[str] = _str(10, "easy")
    xp_reward: Mapped[int] = _int(30)
    is_onboarding: Mapped[bool] = _flag(False)
    is_published: Mapped[bool] = _flag(True)
    order: Mapped[int] = _int(0)

    course: Mapped[Course] = relationship(back_populates="lessons")
    exercises: Mapped[list["Exercise"]] = relationship(
        back_populates="lesson", order_by="Exercise.order", cascade="all, delete-orphan", passive_deletes=True
    )
    signs: Mapped[list[Sign]] = relationship(secondary="lesson_signs", order_by="LessonSign.order", viewonly=True)


class LessonSign(Base):
    """Signs taught in a lesson."""

    __tablename__ = "lesson_signs"
    __table_args__ = (Index(None, "lesson_id", "sign_id", unique=True),)

    id: Mapped[int] = _pk()
    lesson_id: Mapped[int] = _fk("lessons.id", "CASCADE")
    sign_id: Mapped[int] = _fk("signs.id", "RESTRICT")
    order: Mapped[int] = _int(0, small=True)


class Exercise(Base):
    __tablename__ = "exercises"

    id: Mapped[int] = _pk()
    lesson_id: Mapped[int] = _fk("lessons.id", "CASCADE")
    # choose_text | choose_image | matching | order (see app/grading.py)
    type: Mapped[str] = mapped_column(String(20))
    prompt: Mapped[str | None] = mapped_column(String(255))
    prompt_ru: Mapped[str | None] = mapped_column(String(255))
    prompt_en: Mapped[str | None] = mapped_column(String(255))
    # The sign whose video is shown
    sign_id: Mapped[int | None] = _fk("signs.id", "RESTRICT", nullable=True)
    # Shown after answering
    explanation: Mapped[str | None] = mapped_column(String(500))
    explanation_ru: Mapped[str | None] = mapped_column(String(500))
    explanation_en: Mapped[str | None] = mapped_column(String(500))
    order: Mapped[int] = _int(0, small=True)

    lesson: Mapped[Lesson] = relationship(back_populates="exercises")
    options: Mapped[list["ExerciseOption"]] = relationship(
        order_by="ExerciseOption.id", cascade="all, delete-orphan", passive_deletes=True
    )


class ExerciseOption(Base):
    __tablename__ = "exercise_options"

    id: Mapped[int] = _pk()
    exercise_id: Mapped[int] = _fk("exercises.id", "CASCADE")
    text: Mapped[str | None] = mapped_column(String(255))
    text_ru: Mapped[str | None] = mapped_column(String(255))
    text_en: Mapped[str | None] = mapped_column(String(255))
    image: Mapped[str | None] = mapped_column(String(100))
    sign_id: Mapped[int | None] = _fk("signs.id", "RESTRICT", nullable=True)
    is_correct: Mapped[bool] = _flag(False)
    # Correct place for "order" exercises
    position: Mapped[int | None] = mapped_column(SmallInteger)


# ============================== progress ==============================
class UserLessonProgress(Base):
    __tablename__ = "user_lesson_progress"
    __table_args__ = (Index(None, "user_id", "lesson_id", unique=True),)

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    lesson_id: Mapped[int] = _fk("lessons.id", "CASCADE")
    # in_progress | completed
    status: Mapped[str] = _str(20, "in_progress")
    best_accuracy: Mapped[int] = _int(0, small=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


class LessonAttempt(Base):
    __tablename__ = "lesson_attempts"

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    lesson_id: Mapped[int] = _fk("lessons.id", "CASCADE")
    started_at: Mapped[datetime] = _now()
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    correct_count: Mapped[int] = _int(0, small=True)
    total_count: Mapped[int] = _int(0, small=True)
    # 0-100
    accuracy: Mapped[int] = _int(0, small=True)
    xp_earned: Mapped[int] = _int(0)
    duration_seconds: Mapped[int] = _int(0)


class ExerciseAnswer(Base):
    __tablename__ = "exercise_answers"
    __table_args__ = (Index(None, "attempt_id", "exercise_id", unique=True),)

    id: Mapped[int] = _pk()
    attempt_id: Mapped[int] = _fk("lesson_attempts.id", "CASCADE")
    exercise_id: Mapped[int] = _fk("exercises.id", "CASCADE")
    answer: Mapped[Any] = mapped_column(JSONB)
    is_correct: Mapped[bool] = mapped_column(Boolean)
    answered_at: Mapped[datetime] = _now()


class ExerciseReport(Base):
    """A learner reporting a broken or wrong exercise."""

    __tablename__ = "exercise_reports"

    id: Mapped[int] = _pk()
    user_id: Mapped[int | None] = _fk("users.id", "SET NULL", nullable=True)
    exercise_id: Mapped[int] = _fk("exercises.id", "CASCADE")
    # wrong_answer | bad_video | typo | other
    reason: Mapped[str] = mapped_column(String(20))
    comment: Mapped[str | None] = mapped_column(Text)
    # new | reviewed | fixed | rejected
    status: Mapped[str] = _str(20, "new")
    created_at: Mapped[datetime] = _now()


class UserStats(Base):
    __tablename__ = "user_stats"

    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    total_xp: Mapped[int] = _int(0)
    level: Mapped[int] = _int(1, small=True)
    current_streak: Mapped[int] = _int(0, small=True)
    longest_streak: Mapped[int] = _int(0, small=True)
    last_active_date: Mapped[date | None] = mapped_column(Date)
    signs_learned: Mapped[int] = _int(0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    user: Mapped[User] = relationship(back_populates="stats")


class DailyActivity(Base):
    """One row per user per day (in the user's time zone)."""

    __tablename__ = "daily_activities"
    __table_args__ = (Index(None, "user_id", "date", unique=True),)

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    date: Mapped[date] = mapped_column(Date)
    minutes: Mapped[int] = _int(0, small=True)
    xp: Mapped[int] = _int(0)
    lessons_completed: Mapped[int] = _int(0, small=True)
    correct_answers: Mapped[int] = _int(0)
    total_answers: Mapped[int] = _int(0)


class ActivitySession(Base):
    """Time spent in the app; feeds minutes and the activity calendar."""

    __tablename__ = "activity_sessions"
    __table_args__ = (Index(None, "user_id", "started_at"),)

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    # lesson | dictionary | translator | dataset | other
    source: Mapped[str] = mapped_column(String(20))
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    duration_seconds: Mapped[int] = mapped_column(Integer)


class LearnedSign(Base):
    __tablename__ = "learned_signs"
    __table_args__ = (Index(None, "user_id", "sign_id", unique=True),)

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    sign_id: Mapped[int] = _fk("signs.id", "CASCADE")
    learned_at: Mapped[datetime] = _now()


class Achievement(Base):
    __tablename__ = "achievements"

    id: Mapped[int] = _pk()
    code: Mapped[str] = mapped_column(String(50), unique=True)
    title: Mapped[str] = mapped_column(String(100))
    description: Mapped[str | None] = mapped_column(String(255))
    why_it_matters: Mapped[str | None] = mapped_column(Text)
    icon: Mapped[str | None] = mapped_column(String(100))
    # See _condition_met in app/progress.py and AchievementIn in app/schemas/admin.py
    condition_type: Mapped[str] = mapped_column(String(30))
    condition_value: Mapped[int] = mapped_column(Integer)
    course_id: Mapped[int | None] = _fk("courses.id", "SET NULL", nullable=True)
    xp_reward: Mapped[int] = _int(0)
    order: Mapped[int] = _int(0)


class UserAchievement(Base):
    __tablename__ = "user_achievements"
    __table_args__ = (Index(None, "user_id", "achievement_id", unique=True),)

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    achievement_id: Mapped[int] = _fk("achievements.id", "CASCADE")
    unlocked_at: Mapped[datetime] = _now()


class Notification(Base):
    __tablename__ = "notifications"
    __table_args__ = (Index(None, "user_id", "is_read"),)

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    # achievement | reminder | news | system
    type: Mapped[str] = mapped_column(String(30))
    title: Mapped[str] = mapped_column(String(150))
    body: Mapped[str] = mapped_column(Text)
    data: Mapped[Any | None] = mapped_column(JSONB)
    is_read: Mapped[bool] = _flag(False)
    created_at: Mapped[datetime] = _now()


# ============================== dataset collection ==============================
class DatasetCategory(Base):
    __tablename__ = "dataset_categories"

    id: Mapped[int] = _pk()
    name: Mapped[str] = mapped_column(String(100))
    name_ru: Mapped[str | None] = mapped_column(String(100))


class DatasetTopic(Base):
    __tablename__ = "dataset_topics"

    id: Mapped[int] = _pk()
    category_id: Mapped[int | None] = _fk("dataset_categories.id", "SET NULL", nullable=True)
    name: Mapped[str] = mapped_column(String(100))
    name_ru: Mapped[str | None] = mapped_column(String(100))
    description: Mapped[str | None] = mapped_column(String(255))
    # pending | approved | rejected (users can propose topics)
    status: Mapped[str] = _str(20, "approved")
    proposed_by_id: Mapped[int | None] = _fk("users.id", "SET NULL", nullable=True)
    created_at: Mapped[datetime] = _now()


class DatasetWord(Base):
    __tablename__ = "dataset_words"

    id: Mapped[int] = _pk()
    topic_id: Mapped[int] = _fk("dataset_topics.id", "CASCADE")
    word: Mapped[str] = mapped_column(String(255))
    word_ru: Mapped[str | None] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(String(255))
    sign_id: Mapped[int | None] = _fk("signs.id", "SET NULL", nullable=True)
    # Videos each contributor records for this word
    required_takes: Mapped[int] = _int(3, small=True)
    # pending | approved | rejected
    status: Mapped[str] = _str(20, "approved")
    proposed_by_id: Mapped[int | None] = _fk("users.id", "SET NULL", nullable=True)
    order: Mapped[int] = _int(0)
    created_at: Mapped[datetime] = _now()

    samples: Mapped[list["DatasetWordSample"]] = relationship(
        order_by="DatasetWordSample.order", cascade="all, delete-orphan", passive_deletes=True
    )


class DatasetWordSample(Base):
    """Reference video showing contributors how to sign the word."""

    __tablename__ = "dataset_word_samples"

    id: Mapped[int] = _pk()
    word_id: Mapped[int] = _fk("dataset_words.id", "CASCADE")
    video: Mapped[str] = mapped_column(String(100))
    duration_ms: Mapped[int | None] = mapped_column(Integer)
    resolution: Mapped[str | None] = mapped_column(String(10))
    order: Mapped[int] = _int(0, small=True)


class Contribution(Base):
    """A video a user recorded for the sign-recognition dataset."""

    __tablename__ = "contributions"
    __table_args__ = (
        Index(None, "user_id", "word_id", "take_number", unique=True),
        Index(None, "status", "created_at"),
    )

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    word_id: Mapped[int] = _fk("dataset_words.id", "CASCADE")
    take_number: Mapped[int] = mapped_column(SmallInteger)
    video: Mapped[str] = mapped_column(String(100))
    duration_seconds: Mapped[int] = mapped_column(SmallInteger)
    # pending | approved | rejected
    status: Mapped[str] = _str(20, "pending")
    rejection_reason: Mapped[str | None] = mapped_column(String(255))
    reviewed_by_id: Mapped[int | None] = _fk("users.id", "SET NULL", nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = _now()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


# ============================== translator ==============================
class Conversation(Base):
    __tablename__ = "conversations"

    id: Mapped[int] = _pk()
    user_id: Mapped[int] = _fk("users.id", "CASCADE")
    title: Mapped[str | None] = mapped_column(String(150))
    created_at: Mapped[datetime] = _now()
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[int] = _pk()
    conversation_id: Mapped[int] = _fk("conversations.id", "CASCADE")
    # user | assistant
    sender: Mapped[str] = mapped_column(String(20))
    # text | video | audio
    input_type: Mapped[str] = mapped_column(String(10))
    text: Mapped[str | None] = mapped_column(Text)
    input_video: Mapped[str | None] = mapped_column(String(100))
    input_audio: Mapped[str | None] = mapped_column(String(100))
    output_audio: Mapped[str | None] = mapped_column(String(100))
    created_at: Mapped[datetime] = _now()

    signs: Mapped[list[Sign]] = relationship(secondary="message_signs", order_by="MessageSign.order", viewonly=True)


class MessageSign(Base):
    """Signs shown for a message, in order."""

    __tablename__ = "message_signs"

    id: Mapped[int] = _pk()
    message_id: Mapped[int] = _fk("messages.id", "CASCADE")
    sign_id: Mapped[int] = _fk("signs.id", "CASCADE")
    order: Mapped[int] = mapped_column(SmallInteger)


class QuickPhrase(Base):
    """Ready-made phrases for the translator; user_id empty = shown to everyone."""

    __tablename__ = "quick_phrases"

    id: Mapped[int] = _pk()
    user_id: Mapped[int | None] = _fk("users.id", "CASCADE", nullable=True)
    text: Mapped[str] = mapped_column(String(255))
    order: Mapped[int] = _int(0)
    created_at: Mapped[datetime] = _now()


# ============================== app settings ==============================
class AppConfig(Base):
    """Settings of the mobile app that admins change in the dashboard (Settings → App).

    One row (id 1) with the settings as JSON, shaped like schemas.config.AppConfigIn;
    the app reads them at start from GET /app/config.
    """

    __tablename__ = "app_config"

    id: Mapped[int] = mapped_column(SmallInteger, primary_key=True, default=1)
    data: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
    updated_by_id: Mapped[int | None] = _fk("users.id", "SET NULL", nullable=True)

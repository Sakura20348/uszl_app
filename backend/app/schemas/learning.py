from datetime import datetime
from typing import Any, Literal

from pydantic import Field, model_validator

from app.schemas.common import MediaPath, Schema
from app.schemas.dictionary import SignBrief, SignVideoOut
from app.schemas.users import AchievementOut, UserStatsOut

# Same names as the dashboard's lesson builder
ExerciseType = Literal["chooseText", "chooseImage", "matching", "order"]
Difficulty = Literal["easy", "medium", "hard"]


# ===== courses =====
class CourseBase(Schema):
    title: str = Field(min_length=1, max_length=100)
    title_ru: str | None = Field(default=None, max_length=100)
    title_en: str | None = Field(default=None, max_length=100)
    slug: str = Field(min_length=1, max_length=100, pattern=r"^[a-z0-9-]+$")
    subtitle: str | None = Field(default=None, max_length=255)
    subtitle_ru: str | None = Field(default=None, max_length=255)
    subtitle_en: str | None = Field(default=None, max_length=255)
    description: str | None = Field(default=None, max_length=255)
    description_ru: str | None = Field(default=None, max_length=255)
    description_en: str | None = Field(default=None, max_length=255)
    icon: str | None = Field(default=None, max_length=100)
    unit_label: str = Field(default="so'z", max_length=30)
    order: int = 0
    is_published: bool = True


class CourseIn(CourseBase):
    pass


class CourseOut(CourseBase):
    id: int
    icon: MediaPath  # type: ignore[assignment]
    lesson_count: int = 0
    # Only for logged-in users
    completed_lessons: int | None = None


# ===== lessons =====
class LessonBase(Schema):
    title: str = Field(min_length=1, max_length=150)
    title_ru: str | None = Field(default=None, max_length=150)
    title_en: str | None = Field(default=None, max_length=150)
    description: str | None = None
    description_ru: str | None = None
    description_en: str | None = None
    thumbnail: str | None = Field(default=None, max_length=100)
    duration_minutes: int = Field(default=5, ge=1, le=600)
    difficulty: Difficulty = "easy"
    xp_reward: int = Field(default=30, ge=0)
    is_onboarding: bool = False
    is_published: bool = True
    order: int = 0


class LessonIn(LessonBase):
    course_id: int
    # Signs taught in the lesson, in order; left out on an update keeps the current ones
    sign_ids: list[int] | None = None


class LessonOut(LessonBase):
    id: int
    course_id: int
    thumbnail: MediaPath  # type: ignore[assignment]
    sign_count: int = 0
    exercise_count: int = 0
    # Only for logged-in users: in_progress | completed | None (not started)
    status: str | None = None
    best_accuracy: int | None = None


class LessonSignOut(SignBrief):
    videos: list[SignVideoOut] = []


# ===== exercises =====
class OptionOut(Schema):
    """An answer choice as the app sees it (no correct answer inside)."""

    id: int
    text: str | None
    text_ru: str | None = None
    text_en: str | None = None
    image: MediaPath
    sign_id: int | None
    # First video of sign_id, ready to play
    sign_video: str | None = None


class ExerciseOut(Schema):
    id: int
    type: str
    prompt: str | None
    prompt_ru: str | None = None
    prompt_en: str | None = None
    sign_id: int | None
    sign_video: str | None = None
    order: int
    options: list[OptionOut]


class LessonDetailOut(LessonOut):
    signs: list[LessonSignOut] = []
    exercises: list[ExerciseOut] = []


class OptionIn(Schema):
    text: str | None = Field(default=None, max_length=255)
    text_ru: str | None = Field(default=None, max_length=255)
    text_en: str | None = Field(default=None, max_length=255)
    image: str | None = Field(default=None, max_length=100)
    sign_id: int | None = None
    is_correct: bool = False
    # Correct place, for "order" exercises (0, 1, 2, ...)
    position: int | None = Field(default=None, ge=0)


class ExerciseIn(Schema):
    """
    chooseText:  sign video + text options, exactly one isCorrect
    chooseImage: image options (with labels), exactly one isCorrect
    matching:    options are pairs: each has a video (signId) or image, and the text it matches
    order:       options are words; the answer's words have their correct position,
                 extra (wrong) words have no position
    """

    type: ExerciseType
    prompt: str | None = Field(default=None, max_length=255)
    prompt_ru: str | None = Field(default=None, max_length=255)
    prompt_en: str | None = Field(default=None, max_length=255)
    sign_id: int | None = None
    explanation: str | None = Field(default=None, max_length=500)
    explanation_ru: str | None = Field(default=None, max_length=500)
    explanation_en: str | None = Field(default=None, max_length=500)
    options: list[OptionIn] = Field(min_length=2, max_length=12)

    @model_validator(mode="after")
    def _check(self) -> "ExerciseIn":
        opts = self.options
        if self.type in ("chooseText", "chooseImage"):
            if sum(o.is_correct for o in opts) != 1:
                raise ValueError(f"{self.type}: mark exactly one option as correct")
            if self.type == "chooseText" and not all(o.text for o in opts):
                raise ValueError("chooseText: every option needs text")
            if self.type == "chooseImage" and not all(o.image for o in opts):
                raise ValueError("chooseImage: every option needs an image")
        elif self.type == "matching":
            if not all(o.text and (o.sign_id or o.image) for o in opts):
                raise ValueError("matching: every pair needs a video (signId) or image, and a text")
        elif self.type == "order":
            positions = [o.position for o in opts if o.position is not None]
            if not positions or sorted(positions) != list(range(len(positions))):
                raise ValueError("order: give the answer's words positions 0, 1, 2, ... with no gaps")
            if not all(o.text for o in opts):
                raise ValueError("order: every option needs text")
        return self


class AdminOptionOut(OptionIn):
    id: int
    image: MediaPath  # type: ignore[assignment]


class AdminExerciseOut(Schema):
    id: int
    type: str
    prompt: str | None
    prompt_ru: str | None = None
    prompt_en: str | None = None
    sign_id: int | None
    explanation: str | None
    explanation_ru: str | None = None
    explanation_en: str | None = None
    order: int
    options: list[AdminOptionOut]


class ExercisesIn(Schema):
    exercises: list[ExerciseIn] = Field(max_length=50)


# ===== attempts =====
class AttemptOut(Schema):
    id: int
    lesson_id: int
    started_at: datetime
    finished_at: datetime | None
    correct_count: int
    total_count: int
    accuracy: int
    xp_earned: int
    duration_seconds: int


class AnswerIn(Schema):
    """
    chooseText / chooseImage: {"optionId": 12}
    matching: {"pairs": [[videoOptionId, textOptionId], ...]}
    order:    {"optionIds": [3, 1, 2]}
    """

    exercise_id: int
    answer: dict[str, Any]


class AnswerOut(Schema):
    is_correct: bool
    explanation: str | None
    explanation_ru: str | None = None
    explanation_en: str | None = None
    # chooseText / chooseImage: the right option
    correct_option_id: int | None = None
    # order: option ids in the right order
    correct_order: list[int] | None = None


class FinishOut(Schema):
    attempt: AttemptOut
    passed: bool
    status: str
    best_accuracy: int
    stats: UserStatsOut
    unlocked_achievements: list[AchievementOut]


class BuiltinResultIn(Schema):
    """Score of a lesson played with the app's own screens."""

    correct: int = Field(ge=0, le=500)
    wrong: int = Field(ge=0, le=500)
    # How long the lesson took; used for the learning time and the activity calendar
    duration_seconds: int = Field(default=0, ge=0, le=4 * 60 * 60)


class ReportIn(Schema):
    reason: Literal["wrong_answer", "bad_video", "typo", "other"]
    comment: str | None = Field(default=None, max_length=2000)


class ReportOut(Schema):
    id: int
    user_id: int | None
    exercise_id: int
    reason: str
    comment: str | None
    status: str
    created_at: datetime

"""Dataset collection (users record sign videos) and the translator."""

from datetime import datetime
from typing import Literal

from pydantic import Field

from app.schemas.common import MediaPath, Schema
from app.schemas.dictionary import SignBrief

ReviewStatus = Literal["pending", "approved", "rejected"]


# ===== dataset =====
class DatasetCategoryIn(Schema):
    name: str = Field(min_length=1, max_length=100)
    name_ru: str | None = Field(default=None, max_length=100)


class DatasetCategoryOut(DatasetCategoryIn):
    id: int


class DatasetTopicIn(Schema):
    category_id: int | None = None
    name: str = Field(min_length=1, max_length=100)
    name_ru: str | None = Field(default=None, max_length=100)
    description: str | None = Field(default=None, max_length=255)


class AdminDatasetTopicIn(DatasetTopicIn):
    status: ReviewStatus = "approved"


class DatasetTopicOut(DatasetTopicIn):
    id: int
    status: str
    proposed_by_id: int | None
    created_at: datetime
    word_count: int = 0


class SampleIn(Schema):
    video: str = Field(min_length=1, max_length=100)
    duration_ms: int | None = Field(default=None, ge=0)
    resolution: str | None = Field(default=None, max_length=10)
    order: int = 0


class SampleOut(Schema):
    id: int
    video: MediaPath
    duration_ms: int | None
    resolution: str | None
    order: int


class DatasetWordIn(Schema):
    topic_id: int
    word: str = Field(min_length=1, max_length=255)
    word_ru: str | None = Field(default=None, max_length=255)
    description: str | None = Field(default=None, max_length=255)


class AdminDatasetWordIn(DatasetWordIn):
    sign_id: int | None = None
    required_takes: int = Field(default=3, ge=1, le=20)
    status: ReviewStatus = "approved"
    order: int = 0
    samples: list[SampleIn] = []


class DatasetWordOut(Schema):
    id: int
    topic_id: int
    word: str
    word_ru: str | None
    description: str | None
    sign_id: int | None
    required_takes: int
    status: str
    proposed_by_id: int | None
    order: int
    created_at: datetime
    samples: list[SampleOut] = []
    # Only for logged-in users: takes they already recorded
    my_takes: int | None = None


class ContributionIn(Schema):
    # Path from POST /uploads
    video: str = Field(min_length=1, max_length=100)
    duration_seconds: int = Field(ge=1, le=60)


class ContributionOut(Schema):
    id: int
    user_id: int
    word_id: int
    take_number: int
    video: MediaPath
    duration_seconds: int
    status: str
    rejection_reason: str | None
    reviewed_by_id: int | None
    reviewed_at: datetime | None
    created_at: datetime


class ReviewIn(Schema):
    status: Literal["approved", "rejected"]
    rejection_reason: str | None = Field(default=None, max_length=255)


class StatusIn(Schema):
    status: ReviewStatus


# ===== translator =====
class ConversationOut(Schema):
    id: int
    title: str | None
    created_at: datetime
    updated_at: datetime


class MessageIn(Schema):
    input_type: Literal["text", "video", "audio"] = "text"
    text: str | None = Field(default=None, max_length=2000)
    # Uploaded file path, for video / audio input
    input_video: str | None = Field(default=None, max_length=100)
    input_audio: str | None = Field(default=None, max_length=100)


class MessageOut(Schema):
    id: int
    conversation_id: int
    sender: str
    input_type: str
    text: str | None
    input_video: MediaPath
    input_audio: MediaPath
    output_audio: MediaPath
    created_at: datetime
    signs: list[SignBrief] = []


class ExchangeOut(Schema):
    """The user's message and the assistant's reply."""

    message: MessageOut
    reply: MessageOut


class QuickPhraseIn(Schema):
    text: str = Field(min_length=1, max_length=255)
    order: int = 0


class QuickPhraseOut(QuickPhraseIn):
    id: int
    user_id: int | None
    created_at: datetime

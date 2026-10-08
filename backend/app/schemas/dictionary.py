from datetime import datetime
from typing import Literal

from pydantic import Field

from app.schemas.common import MediaPath, Schema

SignKind = Literal["word", "letter", "number", "phrase"]


class CategoryBase(Schema):
    name: str = Field(min_length=1, max_length=100)
    name_ru: str | None = Field(default=None, max_length=100)
    name_en: str | None = Field(default=None, max_length=100)
    slug: str = Field(min_length=1, max_length=100, pattern=r"^[a-z0-9-]+$")
    description: str | None = Field(default=None, max_length=255)
    icon: str | None = Field(default=None, max_length=100)
    unit_label: str = Field(default="imo-ishora", max_length=30)
    is_emergency: bool = False
    is_featured: bool = False
    order: int = 0


class CategoryIn(CategoryBase):
    pass


class CategoryOut(CategoryBase):
    id: int
    sign_count: int = 0


class CategoryBrief(Schema):
    id: int
    slug: str
    name: str
    name_ru: str | None
    name_en: str | None


class SignVideoIn(Schema):
    video: str = Field(min_length=1, max_length=100)
    angle: str = Field(default="front", max_length=10)
    duration_ms: int | None = Field(default=None, ge=0)
    order: int = 0


class SignVideoOut(Schema):
    id: int
    video: MediaPath
    angle: str
    duration_ms: int | None
    order: int


class SignBrief(Schema):
    id: int
    word: str
    transcription: str | None
    transcription_ru: str | None = None
    transcription_en: str | None = None
    translation_ru: str | None
    translation_en: str | None
    kind: str
    thumbnail: MediaPath


class SignOut(SignBrief):
    meaning: str | None
    meaning_ru: str | None = None
    meaning_en: str | None = None
    hand_shape: str | None
    hand_shape_ru: str | None = None
    hand_shape_en: str | None = None
    movement: str | None
    movement_ru: str | None = None
    movement_en: str | None = None
    example_sentence: str | None
    example_sentence_ru: str | None = None
    example_sentence_en: str | None = None
    example_video: MediaPath
    is_published: bool
    view_count: int
    created_at: datetime
    updated_at: datetime
    videos: list[SignVideoOut] = []
    categories: list[CategoryBrief] = []
    related: list[SignBrief] = []
    # Only for logged-in users
    is_saved: bool | None = None


class SignIn(Schema):
    word: str = Field(min_length=1, max_length=255)
    transcription: str | None = Field(default=None, max_length=255)
    transcription_ru: str | None = Field(default=None, max_length=255)
    transcription_en: str | None = Field(default=None, max_length=255)
    translation_ru: str | None = Field(default=None, max_length=255)
    translation_en: str | None = Field(default=None, max_length=255)
    kind: SignKind = "word"
    thumbnail: str | None = Field(default=None, max_length=100)
    meaning: str | None = None
    meaning_ru: str | None = None
    meaning_en: str | None = None
    hand_shape: str | None = None
    hand_shape_ru: str | None = None
    hand_shape_en: str | None = None
    movement: str | None = None
    movement_ru: str | None = None
    movement_en: str | None = None
    example_sentence: str | None = Field(default=None, max_length=500)
    example_sentence_ru: str | None = Field(default=None, max_length=500)
    example_sentence_en: str | None = Field(default=None, max_length=500)
    example_video: str | None = Field(default=None, max_length=100)
    is_published: bool = True
    category_ids: list[int] = []
    related_ids: list[int] = []
    # One video per angle
    videos: list[SignVideoIn] = []


class SavedSignOut(Schema):
    sign: SignBrief
    created_at: datetime


class RecentViewOut(Schema):
    sign: SignBrief
    viewed_at: datetime


class OfflinePackageBase(Schema):
    slug: str = Field(min_length=1, max_length=50, pattern=r"^[a-z0-9-]+$")
    title: str = Field(min_length=1, max_length=100)
    file: str = Field(min_length=1, max_length=100)
    size_bytes: int = Field(default=0, ge=0)
    version: int = Field(default=1, ge=1)
    is_active: bool = True
    order: int = 0


class OfflinePackageIn(OfflinePackageBase):
    pass


class OfflinePackageOut(OfflinePackageBase):
    id: int
    file: MediaPath  # type: ignore[assignment]
    updated_at: datetime

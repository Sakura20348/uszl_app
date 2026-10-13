from datetime import datetime

from pydantic import Field

from app.schemas.common import MediaPath, Schema


class SupportMessageIn(Schema):
    text: str = Field(min_length=1, max_length=2000)


class SupportMessageOut(Schema):
    id: int
    from_admin: bool
    text: str
    is_read: bool
    created_at: datetime


class SupportThreadOut(Schema):
    """A learner's conversation on the dashboard's Messages page."""

    user_id: int
    name: str
    phone: str | None
    email: str | None
    avatar: MediaPath = None
    last_text: str
    last_from_admin: bool
    last_at: datetime
    # The learner's messages no admin has opened yet
    unread: int

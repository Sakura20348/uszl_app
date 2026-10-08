from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, PlainSerializer
from pydantic.alias_generators import to_camel

LanguageCode = Literal["uz", "ru", "en"]


class Schema(BaseModel):
    """camelCase JSON for the app and the dashboard."""

    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, from_attributes=True)


class Page[T](Schema):
    items: list[T]
    total: int


def media_url(path: str | None) -> str | None:
    """Stored file path ("signs/a.mp4") -> URL the clients can load ("/media/signs/a.mp4")."""
    if not path or path.startswith(("http://", "https://", "/")):
        return path
    return f"/media/{path}"


# A file path in the database, sent to clients as a /media URL
MediaPath = Annotated[str | None, PlainSerializer(media_url, return_type=str | None)]


class MediaOut(Schema):
    # Store this in file fields
    path: str
    # Open this to view the file
    url: str
    name: str

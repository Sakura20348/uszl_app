"""Saving uploaded files under MEDIA_DIR (served at /media)."""

import re
import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status

from app.core.config import get_settings
from app.schemas.common import MediaOut, media_url

VIDEO = {"video/mp4": ".mp4", "video/webm": ".webm", "video/quicktime": ".mov"}
IMAGE = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp", "image/gif": ".gif"}
AUDIO = {"audio/mpeg": ".mp3", "audio/mp4": ".m4a", "audio/aac": ".aac", "audio/wav": ".wav", "audio/webm": ".weba", "audio/ogg": ".ogg"}


def _stored_name(filename: str | None, extension: str) -> str:
    """"Mushuk (1).MP4" -> "Mushuk-1.mp4": safe for URLs, short, with the right extension."""
    stem = re.sub(r"[^A-Za-z0-9_-]+", "-", Path(filename or "").stem).strip("-")[:40]
    return f"{stem or 'file'}{extension}"


async def save_upload(file: UploadFile, folder: str, allowed: dict[str, str]) -> MediaOut:
    settings = get_settings()
    extension = allowed.get(file.content_type or "")
    if extension is None:
        kinds = ", ".join(sorted({t.split("/")[0] for t in allowed}))
        raise HTTPException(status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, f"Unsupported file type; upload {kinds}")

    # A random folder keeps names unique; the original name stays readable in the editor.
    # Paths must fit the varchar(100) file columns.
    relative = f"{folder}/{uuid.uuid4().hex}/{_stored_name(file.filename, extension)}"
    path = Path(settings.media_dir) / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    limit = settings.max_upload_mb * 1024 * 1024
    size = 0
    try:
        with path.open("wb") as out:
            while chunk := await file.read(1024 * 1024):
                size += len(chunk)
                if size > limit:
                    raise HTTPException(status.HTTP_413_CONTENT_TOO_LARGE, f"Files up to {settings.max_upload_mb} MB")
                out.write(chunk)
    except BaseException:
        path.unlink(missing_ok=True)
        raise
    return MediaOut(path=relative, url=media_url(relative) or "", name=file.filename or relative)

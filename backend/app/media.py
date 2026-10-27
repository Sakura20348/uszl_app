"""Saving uploaded files under MEDIA_DIR (served at /media)."""

import asyncio
import re
import shutil
import subprocess
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


def _make_playable(path: Path) -> None:
    """Phones only play H.264 in yuv420p; other videos (e.g. yuv444p) are re-encoded in place. Without ffmpeg they stay as uploaded."""
    if not (shutil.which("ffmpeg") and shutil.which("ffprobe")):
        return
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=codec_name,pix_fmt", "-of", "csv=p=0", str(path)],
        capture_output=True, text=True,
    )
    if probe.returncode != 0 or probe.stdout.strip() == "h264,yuv420p":
        return
    tmp = path.with_suffix(".tmp.mp4")
    result = subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", str(path), "-c:v", "libx264", "-profile:v", "main", "-pix_fmt", "yuv420p",
         "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2", "-crf", "20", "-movflags", "+faststart", "-c:a", "aac", str(tmp)],
        capture_output=True,
    )
    if result.returncode == 0:
        tmp.replace(path)
    else:
        tmp.unlink(missing_ok=True)


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
    if extension == ".mp4":
        await asyncio.to_thread(_make_playable, path)
    return MediaOut(path=relative, url=media_url(relative) or "", name=file.filename or relative)

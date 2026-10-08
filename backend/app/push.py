"""Push notifications through Firebase Cloud Messaging (HTTP v1 API).

Notifications are always saved in the database first (the app's notification list); push only
tells the phone about them. Turned off while FCM_CREDENTIALS_FILE is empty.
"""

import asyncio
import json
import logging
from dataclasses import dataclass
from pathlib import Path

import httpx
from fastapi import BackgroundTasks
from fastapi.concurrency import run_in_threadpool
from google.auth.transport.requests import Request
from google.oauth2 import service_account
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.db import SessionLocal
from app.models import Device, Notification, NotificationSettings

log = logging.getLogger("uvicorn.error")

SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
# Requests to FCM at the same time
CONCURRENCY = 20


@dataclass
class PushMessage:
    user_id: int
    notification_id: int
    type: str
    title: str
    body: str


class FcmClient:
    def __init__(self) -> None:
        self._credentials: service_account.Credentials | None = None
        self._project_id: str | None = None
        self._loaded = False
        self._lock = asyncio.Lock()

    def _load(self) -> None:
        if self._loaded:
            return
        self._loaded = True
        path = get_settings().fcm_credentials_file
        if not path:
            return
        try:
            info = json.loads(Path(path).read_text())
            self._credentials = service_account.Credentials.from_service_account_info(info, scopes=[SCOPE])
            self._project_id = info["project_id"]
            log.info("Push notifications on (Firebase project %s)", self._project_id)
        except (OSError, ValueError, KeyError) as e:
            log.error("Push notifications off: can't read FCM_CREDENTIALS_FILE %s (%s)", path, e)

    @property
    def enabled(self) -> bool:
        self._load()
        return self._credentials is not None

    async def _token(self, force: bool = False) -> str:
        assert self._credentials is not None
        async with self._lock:
            if force or not self._credentials.valid:
                await run_in_threadpool(self._credentials.refresh, Request())
            return self._credentials.token  # type: ignore[return-value]

    async def send(self, client: httpx.AsyncClient, token: str, message: PushMessage) -> str:
        """"ok", "invalid" (the app was removed or the token is stale) or "error"."""
        settings = get_settings()
        payload = {
            "message": {
                "token": token,
                "notification": {"title": message.title, "body": message.body},
                # Lets the app open this notification when it's tapped
                "data": {"notificationId": str(message.notification_id), "type": message.type},
                "android": {"priority": "high", "notification": {"channel_id": settings.fcm_android_channel}},
                "apns": {"payload": {"aps": {"sound": "default"}}},
            }
        }
        url = f"{settings.fcm_api_url}/v1/projects/{self._project_id}/messages:send"
        for attempt in range(2):
            access = await self._token(force=attempt > 0)
            try:
                response = await client.post(url, json=payload, headers={"Authorization": f"Bearer {access}"})
            except httpx.HTTPError as e:
                log.warning("FCM unreachable: %s", e)
                return "error"
            if response.status_code == 200:
                return "ok"
            if response.status_code == 401 and attempt == 0:
                continue  # access token expired early: get a new one and retry
            error = response.text
            # Token no longer belongs to an installed app
            if response.status_code == 404 or "UNREGISTERED" in error or (
                response.status_code == 400 and "registration token" in error.lower()
            ):
                return "invalid"
            log.warning("FCM error %s: %s", response.status_code, error[:300])
            return "error"
        return "error"


fcm = FcmClient()


async def deliver(messages: list[PushMessage]) -> None:
    """Sends each message to its user's phones; turns off tokens FCM says are gone."""
    if not messages or not fcm.enabled:
        return
    async with SessionLocal() as db:
        user_ids = {m.user_id for m in messages}
        # The "general" switch in the app's notification settings turns push off
        muted = set(
            await db.scalars(
                select(NotificationSettings.user_id).where(
                    NotificationSettings.user_id.in_(user_ids), NotificationSettings.general.is_(False)
                )
            )
        )
        devices = (
            await db.execute(
                select(Device.user_id, Device.token).where(
                    Device.user_id.in_(user_ids - muted), Device.is_active.is_(True)
                )
            )
        ).all()
        tokens: dict[int, list[str]] = {}
        for user_id, token in devices:
            tokens.setdefault(user_id, []).append(token)

        limit = asyncio.Semaphore(CONCURRENCY)
        invalid: list[str] = []

        async with httpx.AsyncClient(timeout=10) as client:

            async def one(token: str, message: PushMessage) -> None:
                async with limit:
                    if await fcm.send(client, token, message) == "invalid":
                        invalid.append(token)

            await asyncio.gather(*(one(t, m) for m in messages for t in tokens.get(m.user_id, [])))

        if invalid:
            await db.execute(update(Device).where(Device.token.in_(invalid)).values(is_active=False))
            await db.commit()
        sent = sum(len(tokens.get(m.user_id, [])) for m in messages) - len(invalid)
        log.info("Push: %d sent, %d stale tokens turned off", sent, len(invalid))


# ===== used by the routes =====
def queue_push(db: AsyncSession, notification: Notification) -> None:
    """Remember a new notification; push_pending() sends it once it's committed."""
    db.info.setdefault("push", []).append(notification)


def push_pending(db: AsyncSession, background: BackgroundTasks) -> None:
    """After commit: send the queued notifications in the background (the request doesn't wait)."""
    pending: list[Notification] = db.info.pop("push", [])
    messages = [PushMessage(n.user_id, n.id, n.type, n.title, n.body) for n in pending if n.id is not None]
    if messages and fcm.enabled:
        background.add_task(deliver, messages)

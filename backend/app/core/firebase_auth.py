"""Checks Firebase Authentication ID tokens sent by the app."""

import json
import logging
from dataclasses import dataclass
from pathlib import Path

import httpx
from fastapi.concurrency import run_in_threadpool
from google.auth import exceptions as google_exceptions
from google.auth.transport.requests import Request
from google.oauth2 import id_token, service_account

from app.core.config import get_settings


@dataclass
class FirebaseIdentity:
    uid: str
    email: str | None
    email_verified: bool
    name: str | None


class FirebaseAuthError(Exception):
    pass


def _verify(token: str) -> dict:
    # Checks the signature against Google's public keys, the expiry,
    # and that the token was issued for our Firebase project
    return id_token.verify_firebase_token(token, Request(), audience=get_settings().firebase_project_id)


async def verify_firebase_token(token: str) -> FirebaseIdentity:
    try:
        claims = await run_in_threadpool(_verify, token)
    except (ValueError, google_exceptions.GoogleAuthError) as e:
        raise FirebaseAuthError("Invalid or expired Firebase token") from e
    if not claims or not claims.get("sub"):
        raise FirebaseAuthError("Invalid Firebase token")
    email = claims.get("email")
    return FirebaseIdentity(
        uid=claims["sub"],
        email=email.lower() if email else None,
        email_verified=bool(claims.get("email_verified")),
        name=claims.get("name"),
    )


# ===== deleting Firebase accounts =====
# When an account is deleted here, its Firebase login (email + password, Google, ...) is deleted too.
# Otherwise the email stays taken in Firebase and can't sign up again with a new password.
_ADMIN_SCOPE = "https://www.googleapis.com/auth/cloud-platform"
_IDENTITY_API = "https://identitytoolkit.googleapis.com/v1"
_log = logging.getLogger("uvicorn.error")
_admin: service_account.Credentials | None = None


def _admin_token() -> tuple[str, str] | None:
    """(access token, project id) from the service-account key (FCM_CREDENTIALS_FILE); None when not set."""
    global _admin
    path = get_settings().fcm_credentials_file
    if not path:
        return None
    if _admin is None:
        info = json.loads(Path(path).read_text())
        _admin = service_account.Credentials.from_service_account_info(info, scopes=[_ADMIN_SCOPE])
    if not _admin.valid:
        _admin.refresh(Request())
    return _admin.token, _admin.project_id  # type: ignore[return-value]


async def delete_firebase_users(uids: list[str]) -> bool:
    """Deletes these Firebase users; True when done (or nothing to do). Failures are logged, not raised."""
    if not uids:
        return True
    try:
        admin = await run_in_threadpool(_admin_token)
        if admin is None:
            _log.warning("Firebase users not deleted (FCM_CREDENTIALS_FILE not set): %s", uids)
            return False
        token, project = admin
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.post(
                f"{_IDENTITY_API}/projects/{project}/accounts:batchDelete",
                json={"localIds": uids, "force": True},
                headers={"Authorization": f"Bearer {token}"},
            )
        errors = response.json().get("errors") if response.status_code == 200 else None
        if response.status_code != 200 or errors:
            _log.error("Firebase users not deleted (%s): %s", response.status_code, errors or response.text[:300])
            return False
        return True
    except (OSError, ValueError, KeyError, httpx.HTTPError, google_exceptions.GoogleAuthError) as e:
        _log.error("Firebase users not deleted: %s", e)
        return False

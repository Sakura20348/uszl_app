"""Checks Firebase Authentication ID tokens sent by the app."""

from dataclasses import dataclass

from fastapi.concurrency import run_in_threadpool
from google.auth import exceptions as google_exceptions
from google.auth.transport.requests import Request
from google.oauth2 import id_token

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

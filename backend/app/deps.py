from datetime import UTC, datetime, timedelta
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_token
from app.db import get_db
from app.models import User

DB = Annotated[AsyncSession, Depends(get_db)]

_bearer = HTTPBearer(auto_error=False)
Credentials = Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)]


async def _user_from(db: AsyncSession, credentials: HTTPAuthorizationCredentials | None) -> User | None:
    user_id = decode_token(credentials.credentials, "access") if credentials else None
    user = await db.get(User, user_id) if user_id else None
    return user if user and user.is_active else None


async def get_current_user(db: DB, credentials: Credentials) -> User:
    user = await _user_from(db, credentials)
    if user is None:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "Not authenticated", headers={"WWW-Authenticate": "Bearer"}
        )
    # last_login doubles as "last seen": the dashboard's online status reads it. The app calls the API
    # every 30 s while open, so refresh it at most once a minute instead of writing on every request.
    now = datetime.now(UTC)
    # Right after the app said it was closed, the first request marks the user online again
    came_back = user.offline_at is not None and user.last_login is not None and user.offline_at >= user.last_login
    if user.last_login is None or came_back or now - user.last_login > timedelta(minutes=1):
        user.last_login = now
        await db.commit()
    return user


async def get_optional_user(db: DB, credentials: Credentials) -> User | None:
    """The logged-in user on public routes that show more when you are logged in."""
    return await _user_from(db, credentials)


async def get_staff(user: Annotated[User, Depends(get_current_user)]) -> User:
    if not user.is_staff:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admins only")
    return user


async def get_superuser(user: Annotated[User, Depends(get_staff)]) -> User:
    if not user.is_superuser:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only a superuser can do this")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
OptionalUser = Annotated[User | None, Depends(get_optional_user)]
Staff = Annotated[User, Depends(get_staff)]
Superuser = Annotated[User, Depends(get_superuser)]

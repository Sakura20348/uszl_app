"""Deleting an account, here and in Firebase."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.firebase_auth import delete_firebase_users
from app.models import SocialAccount, User

# SocialAccount.provider of logins made through Firebase (email + password, Google, Apple, phone)
FIREBASE = "firebase"


async def delete_account(db: AsyncSession, user: User) -> None:
    """Deletes the user and everything saved for them (the database cascades), then their Firebase
    login, so the same email can sign up again later, with any password."""
    uids = list(
        await db.scalars(
            select(SocialAccount.uid).where(SocialAccount.user_id == user.id, SocialAccount.provider == FIREBASE)
        )
    )
    await db.delete(user)
    await db.commit()
    # After the commit: the account is gone even if Firebase can't be reached (that's logged)
    await delete_firebase_users(uids)

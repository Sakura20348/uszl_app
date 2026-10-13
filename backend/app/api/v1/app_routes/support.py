from fastapi import APIRouter, status
from sqlalchemy import select, update

from app.deps import DB, CurrentUser
from app.models import SupportMessage
from app.schemas.support import SupportMessageIn, SupportMessageOut

router = APIRouter(prefix="/support", tags=["app: support"])


@router.get("/messages", response_model=list[SupportMessageOut])
async def my_messages(user: CurrentUser, db: DB) -> list[SupportMessage]:
    """The learner's conversation with the team, oldest first; replies become read."""
    messages = list(await db.scalars(
        select(SupportMessage).where(SupportMessage.user_id == user.id).order_by(SupportMessage.created_at, SupportMessage.id)
    ))
    await db.execute(
        update(SupportMessage)
        .where(SupportMessage.user_id == user.id, SupportMessage.from_admin.is_(True), SupportMessage.is_read.is_(False))
        .values(is_read=True)
    )
    await db.commit()
    return messages


@router.post("/messages", response_model=SupportMessageOut, status_code=status.HTTP_201_CREATED)
async def write_to_support(body: SupportMessageIn, user: CurrentUser, db: DB) -> SupportMessage:
    """A question or feedback for the team; admins answer on the dashboard's Messages page."""
    message = SupportMessage(user_id=user.id, text=body.text.strip())
    db.add(message)
    await db.commit()
    await db.refresh(message)
    return message

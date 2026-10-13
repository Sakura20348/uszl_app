from fastapi import APIRouter, BackgroundTasks, HTTPException, status
from sqlalchemy import func, select, update

from app.deps import DB, Staff
from app.models import Notification, SupportMessage, User
from app.push import push_pending, queue_push
from app.schemas.support import SupportMessageIn, SupportMessageOut, SupportThreadOut

router = APIRouter(prefix="/support", tags=["admin: support"])

# Title of the notification a learner gets for a reply, in their app language
REPLY_TITLE = {"uz": "Qoʻllab-quvvatlash javob berdi", "ru": "Ответ поддержки", "en": "Support replied"}


@router.get("/threads", response_model=list[SupportThreadOut])
async def threads(db: DB) -> list[SupportThreadOut]:
    """Every learner who wrote to support, newest conversation first."""
    last_id = select(SupportMessage.user_id, func.max(SupportMessage.id).label("id")).group_by(SupportMessage.user_id).subquery()
    unread = (
        select(SupportMessage.user_id, func.count().label("n"))
        .where(SupportMessage.from_admin.is_(False), SupportMessage.is_read.is_(False))
        .group_by(SupportMessage.user_id)
        .subquery()
    )
    rows = await db.execute(
        select(User, SupportMessage, func.coalesce(unread.c.n, 0))
        .join(last_id, last_id.c.user_id == User.id)
        .join(SupportMessage, SupportMessage.id == last_id.c.id)
        .outerjoin(unread, unread.c.user_id == User.id)
        .order_by(SupportMessage.created_at.desc())
    )
    return [
        SupportThreadOut(
            user_id=u.id, name=u.full_name or "", phone=u.phone, email=u.email, avatar=u.avatar,
            last_text=m.text, last_from_admin=m.from_admin, last_at=m.created_at, unread=n,
        )
        for u, m, n in rows.all()
    ]


@router.get("/threads/{user_id}", response_model=list[SupportMessageOut])
async def thread(user_id: int, db: DB) -> list[SupportMessage]:
    """One learner's conversation, oldest first; their messages become read."""
    messages = list(await db.scalars(
        select(SupportMessage).where(SupportMessage.user_id == user_id).order_by(SupportMessage.created_at, SupportMessage.id)
    ))
    await db.execute(
        update(SupportMessage)
        .where(SupportMessage.user_id == user_id, SupportMessage.from_admin.is_(False), SupportMessage.is_read.is_(False))
        .values(is_read=True)
    )
    await db.commit()
    return messages


@router.post("/threads/{user_id}", response_model=SupportMessageOut, status_code=status.HTTP_201_CREATED)
async def reply(user_id: int, body: SupportMessageIn, admin: Staff, db: DB, background: BackgroundTasks) -> SupportMessage:
    """Answers the learner; they get a push notification that opens the conversation in the app."""
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    text = body.text.strip()
    message = SupportMessage(user_id=user_id, from_admin=True, admin_id=admin.id, text=text)
    db.add(message)
    notification = Notification(
        user_id=user_id, type="support", title=REPLY_TITLE.get(user.language, REPLY_TITLE["uz"]), body=text,
        data={"support": True},
    )
    db.add(notification)
    queue_push(db, notification)
    await db.commit()
    push_pending(db, background)
    await db.refresh(message)
    return message

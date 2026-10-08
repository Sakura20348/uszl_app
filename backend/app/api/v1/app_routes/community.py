from fastapi import APIRouter, HTTPException, Query, Response, UploadFile, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import selectinload

from app.api.v1.common import get_or_404
from app.deps import DB, CurrentUser, OptionalUser
from app.media import AUDIO, IMAGE, VIDEO, save_upload
from app.models import (
    Contribution,
    Conversation,
    DatasetCategory,
    DatasetTopic,
    DatasetWord,
    Message,
    MessageSign,
    QuickPhrase,
    User,
)
from app.schemas.common import MediaOut
from app.schemas.community import (
    ContributionIn,
    ContributionOut,
    ConversationOut,
    DatasetCategoryOut,
    DatasetTopicIn,
    DatasetTopicOut,
    DatasetWordIn,
    DatasetWordOut,
    ExchangeOut,
    MessageIn,
    MessageOut,
    QuickPhraseIn,
    QuickPhraseOut,
)
from app.schemas.dictionary import SignBrief
from app.translator import text_to_signs

router = APIRouter()

TITLE_LENGTH = 60


# ===== uploads =====
@router.post("/uploads", response_model=MediaOut, status_code=status.HTTP_201_CREATED)
async def upload(file: UploadFile, user: CurrentUser) -> MediaOut:
    """Videos for the dataset, video/audio for the translator, images for the avatar."""
    return await save_upload(file, f"users/{user.id}", VIDEO | AUDIO | IMAGE)


# ===== dataset collection =====
@router.get("/dataset/categories", response_model=list[DatasetCategoryOut], tags=["dataset"])
async def dataset_categories(db: DB) -> list[DatasetCategory]:
    return list(await db.scalars(select(DatasetCategory).order_by(DatasetCategory.id)))


@router.get("/dataset/topics", response_model=list[DatasetTopicOut], tags=["dataset"])
async def dataset_topics(db: DB, category_id: int | None = Query(default=None, alias="categoryId")) -> list[DatasetTopicOut]:
    counts = (
        select(DatasetWord.topic_id, func.count().label("n"))
        .where(DatasetWord.status == "approved")
        .group_by(DatasetWord.topic_id)
        .subquery()
    )
    query = (
        select(DatasetTopic, func.coalesce(counts.c.n, 0))
        .outerjoin(counts, counts.c.topic_id == DatasetTopic.id)
        .where(DatasetTopic.status == "approved")
    )
    if category_id is not None:
        query = query.where(DatasetTopic.category_id == category_id)
    rows = await db.execute(query.order_by(DatasetTopic.name))
    return [DatasetTopicOut.model_validate(t).model_copy(update={"word_count": n}) for t, n in rows.all()]


@router.post("/dataset/topics", response_model=DatasetTopicOut, status_code=status.HTTP_201_CREATED, tags=["dataset"])
async def propose_topic(body: DatasetTopicIn, user: CurrentUser, db: DB) -> DatasetTopic:
    """A new topic waits for an admin to approve it."""
    if body.category_id is not None:
        await get_or_404(db, DatasetCategory, body.category_id, "Category")
    topic = DatasetTopic(**body.model_dump(), status="pending", proposed_by_id=user.id)
    db.add(topic)
    await db.commit()
    await db.refresh(topic)
    return topic


@router.get("/dataset/topics/{topic_id}/words", response_model=list[DatasetWordOut], tags=["dataset"])
async def dataset_words(topic_id: int, db: DB, user: OptionalUser) -> list[DatasetWordOut]:
    words = list(await db.scalars(
        select(DatasetWord)
        .where(DatasetWord.topic_id == topic_id, DatasetWord.status == "approved")
        .options(selectinload(DatasetWord.samples))
        .order_by(DatasetWord.order, DatasetWord.id)
    ))
    takes: dict[int, int] = {}
    if user and words:
        takes = dict((await db.execute(
            select(Contribution.word_id, func.count())
            .where(Contribution.user_id == user.id, Contribution.word_id.in_([w.id for w in words]))
            .group_by(Contribution.word_id)
        )).all())
    return [
        DatasetWordOut.model_validate(w).model_copy(update={"my_takes": takes.get(w.id, 0) if user else None})
        for w in words
    ]


@router.post("/dataset/words", response_model=DatasetWordOut, status_code=status.HTTP_201_CREATED, tags=["dataset"])
async def propose_word(body: DatasetWordIn, user: CurrentUser, db: DB) -> DatasetWordOut:
    topic = await get_or_404(db, DatasetTopic, body.topic_id, "Topic")
    if topic.status != "approved":
        raise HTTPException(status.HTTP_409_CONFLICT, "This topic is not approved yet")
    word = DatasetWord(**body.model_dump(), status="pending", proposed_by_id=user.id)
    db.add(word)
    await db.commit()
    await db.refresh(word, ["samples"])
    return DatasetWordOut.model_validate(word)


@router.post("/dataset/words/{word_id}/contributions", response_model=ContributionOut, status_code=status.HTTP_201_CREATED, tags=["dataset"])
async def contribute(word_id: int, body: ContributionIn, user: CurrentUser, db: DB) -> Contribution:
    word = await get_or_404(db, DatasetWord, word_id, "Word")
    if word.status != "approved":
        raise HTTPException(status.HTTP_409_CONFLICT, "This word is not approved yet")
    if not body.video.startswith(f"users/{user.id}/"):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Upload the video with POST /uploads first")
    takes = await db.scalar(
        select(func.coalesce(func.max(Contribution.take_number), 0)).where(
            Contribution.user_id == user.id, Contribution.word_id == word_id
        )
    ) or 0
    if takes >= word.required_takes:
        raise HTTPException(status.HTTP_409_CONFLICT, f"You already recorded all {word.required_takes} takes")
    contribution = Contribution(
        user_id=user.id, word_id=word_id, take_number=takes + 1, video=body.video, duration_seconds=body.duration_seconds
    )
    db.add(contribution)
    await db.commit()
    await db.refresh(contribution)
    return contribution


@router.get("/dataset/my-contributions", response_model=list[ContributionOut], tags=["dataset"])
async def my_contributions(user: CurrentUser, db: DB) -> list[Contribution]:
    rows = await db.scalars(
        select(Contribution).where(Contribution.user_id == user.id).order_by(Contribution.created_at.desc())
    )
    return list(rows)


@router.delete("/dataset/contributions/{contribution_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["dataset"])
async def delete_contribution(contribution_id: int, user: CurrentUser, db: DB) -> Response:
    contribution = await db.get(Contribution, contribution_id)
    if contribution is None or contribution.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contribution not found")
    if contribution.status != "pending":
        raise HTTPException(status.HTTP_409_CONFLICT, "Reviewed recordings can't be deleted")
    await db.delete(contribution)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== translator =====
async def _own_conversation(db: DB, user: User, conversation_id: int) -> Conversation:
    conversation = await db.get(Conversation, conversation_id)
    if conversation is None or conversation.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Conversation not found")
    return conversation


def _message_out(message: Message, signs) -> MessageOut:
    columns = {c.key: getattr(message, c.key) for c in Message.__table__.columns}
    return MessageOut.model_validate({**columns, "signs": [SignBrief.model_validate(s) for s in signs]})


@router.get("/conversations", response_model=list[ConversationOut], tags=["translator"])
async def conversations(user: CurrentUser, db: DB) -> list[Conversation]:
    rows = await db.scalars(
        select(Conversation).where(Conversation.user_id == user.id).order_by(Conversation.updated_at.desc())
    )
    return list(rows)


@router.post("/conversations", response_model=ConversationOut, status_code=status.HTTP_201_CREATED, tags=["translator"])
async def new_conversation(user: CurrentUser, db: DB) -> Conversation:
    conversation = Conversation(user_id=user.id)
    db.add(conversation)
    await db.commit()
    await db.refresh(conversation)
    return conversation


@router.delete("/conversations/{conversation_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["translator"])
async def delete_conversation(conversation_id: int, user: CurrentUser, db: DB) -> Response:
    await db.delete(await _own_conversation(db, user, conversation_id))
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/conversations/{conversation_id}/messages", response_model=list[MessageOut], tags=["translator"])
async def messages(conversation_id: int, user: CurrentUser, db: DB) -> list[MessageOut]:
    await _own_conversation(db, user, conversation_id)
    rows = await db.scalars(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .options(selectinload(Message.signs))
        .order_by(Message.created_at, Message.id)
    )
    return [_message_out(m, m.signs) for m in rows]


@router.post("/conversations/{conversation_id}/messages", response_model=ExchangeOut, status_code=status.HTTP_201_CREATED, tags=["translator"])
async def send(conversation_id: int, body: MessageIn, user: CurrentUser, db: DB) -> ExchangeOut:
    """
    Text is translated into signs: dictionary words and phrases, and unknown words
    fingerspelled with letter signs. Video and audio are stored, but recognizing them
    is not connected yet, so their reply has no signs.
    """
    conversation = await _own_conversation(db, user, conversation_id)
    if body.input_type == "text" and not (body.text and body.text.strip()):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Write some text")
    if body.input_type == "video" and not body.input_video:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Upload the video with POST /uploads first")
    if body.input_type == "audio" and not body.input_audio:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Upload the audio with POST /uploads first")
    for path in (body.input_video, body.input_audio):
        if path and not path.startswith(f"users/{user.id}/"):
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Use a file you uploaded with POST /uploads")

    message = Message(conversation_id=conversation.id, sender="user", **body.model_dump())
    signs = await text_to_signs(db, body.text) if body.input_type == "text" and body.text else []
    reply = Message(conversation_id=conversation.id, sender="assistant", input_type="text", text=body.text if signs else None)
    db.add_all([message, reply])
    await db.flush()
    db.add_all(MessageSign(message_id=reply.id, sign_id=s.id, order=i) for i, s in enumerate(signs))
    if not conversation.title and body.text:
        conversation.title = body.text.strip()[:TITLE_LENGTH]
    conversation.updated_at = func.now()
    await db.commit()
    await db.refresh(message)
    await db.refresh(reply)
    return ExchangeOut(message=_message_out(message, []), reply=_message_out(reply, signs))


# ===== quick phrases =====
@router.get("/quick-phrases", response_model=list[QuickPhraseOut], tags=["translator"])
async def quick_phrases(user: CurrentUser, db: DB) -> list[QuickPhrase]:
    """Phrases for everyone first, then the user's own."""
    rows = await db.scalars(
        select(QuickPhrase)
        .where(or_(QuickPhrase.user_id.is_(None), QuickPhrase.user_id == user.id))
        .order_by(QuickPhrase.user_id.is_not(None), QuickPhrase.order, QuickPhrase.id)
    )
    return list(rows)


@router.post("/quick-phrases", response_model=QuickPhraseOut, status_code=status.HTTP_201_CREATED, tags=["translator"])
async def add_phrase(body: QuickPhraseIn, user: CurrentUser, db: DB) -> QuickPhrase:
    phrase = QuickPhrase(user_id=user.id, **body.model_dump())
    db.add(phrase)
    await db.commit()
    await db.refresh(phrase)
    return phrase


@router.delete("/quick-phrases/{phrase_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["translator"])
async def delete_phrase(phrase_id: int, user: CurrentUser, db: DB) -> Response:
    phrase = await db.get(QuickPhrase, phrase_id)
    if phrase is None or phrase.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Phrase not found")
    await db.delete(phrase)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)

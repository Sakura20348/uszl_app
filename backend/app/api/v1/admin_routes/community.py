from datetime import UTC, datetime
from typing import Literal

from fastapi import APIRouter, HTTPException, Query, Response, status
from sqlalchemy import delete, func, select
from sqlalchemy.orm import selectinload

from app.api.v1.common import commit, crud_routes, get_or_404
from app.deps import DB, Staff
from app.models import Contribution, DatasetCategory, DatasetTopic, DatasetWord, DatasetWordSample, QuickPhrase
from app.schemas.common import Page
from app.schemas.community import (
    AdminDatasetTopicIn,
    AdminDatasetWordIn,
    ContributionOut,
    DatasetCategoryIn,
    DatasetCategoryOut,
    DatasetTopicOut,
    DatasetWordOut,
    QuickPhraseIn,
    QuickPhraseOut,
    ReviewIn,
    ReviewStatus,
)

router = APIRouter()
TAG = "admin: dataset & translator"

crud_routes(router, "/dataset/categories", DatasetCategory, DatasetCategoryIn, DatasetCategoryOut, (DatasetCategory.id,), TAG)


# ===== topics =====
@router.get("/dataset/topics", response_model=list[DatasetTopicOut], tags=[TAG])
async def list_topics(db: DB, status_: ReviewStatus | None = Query(default=None, alias="status")) -> list[DatasetTopicOut]:
    counts = select(DatasetWord.topic_id, func.count().label("n")).group_by(DatasetWord.topic_id).subquery()
    query = select(DatasetTopic, func.coalesce(counts.c.n, 0)).outerjoin(counts, counts.c.topic_id == DatasetTopic.id)
    if status_:
        query = query.where(DatasetTopic.status == status_)
    rows = await db.execute(query.order_by(DatasetTopic.created_at.desc()))
    return [DatasetTopicOut.model_validate(t).model_copy(update={"word_count": n}) for t, n in rows.all()]


@router.post("/dataset/topics", response_model=DatasetTopicOut, status_code=status.HTTP_201_CREATED, tags=[TAG])
async def create_topic(body: AdminDatasetTopicIn, admin: Staff, db: DB) -> DatasetTopic:
    topic = DatasetTopic(**body.model_dump(), proposed_by_id=admin.id)
    db.add(topic)
    await commit(db)
    await db.refresh(topic)
    return topic


@router.put("/dataset/topics/{topic_id}", response_model=DatasetTopicOut, tags=[TAG])
async def update_topic(topic_id: int, body: AdminDatasetTopicIn, db: DB) -> DatasetTopic:
    """Also used to approve or reject a proposed topic (status)."""
    topic = await get_or_404(db, DatasetTopic, topic_id, "Topic")
    for field, value in body.model_dump().items():
        setattr(topic, field, value)
    await commit(db)
    await db.refresh(topic)
    return topic


@router.delete("/dataset/topics/{topic_id}", status_code=status.HTTP_204_NO_CONTENT, tags=[TAG])
async def delete_topic(topic_id: int, db: DB) -> Response:
    await db.delete(await get_or_404(db, DatasetTopic, topic_id, "Topic"))
    await commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== words =====
@router.get("/dataset/words", response_model=list[DatasetWordOut], tags=[TAG])
async def list_words(
    db: DB,
    topic_id: int | None = Query(default=None, alias="topicId"),
    status_: ReviewStatus | None = Query(default=None, alias="status"),
) -> list[DatasetWord]:
    query = select(DatasetWord).options(selectinload(DatasetWord.samples))
    if topic_id is not None:
        query = query.where(DatasetWord.topic_id == topic_id)
    if status_:
        query = query.where(DatasetWord.status == status_)
    return list(await db.scalars(query.order_by(DatasetWord.topic_id, DatasetWord.order, DatasetWord.id)))


async def _save_word(db: DB, word: DatasetWord, body: AdminDatasetWordIn) -> DatasetWord:
    await get_or_404(db, DatasetTopic, body.topic_id, "Topic")
    for field, value in body.model_dump(exclude={"samples"}).items():
        setattr(word, field, value)
    db.add(word)
    await db.flush()
    await db.execute(delete(DatasetWordSample).where(DatasetWordSample.word_id == word.id))
    word_id = word.id
    db.add_all(DatasetWordSample(word_id=word_id, **s.model_dump()) for s in body.samples)
    await commit(db)
    db.expire_all()
    saved = await db.scalar(select(DatasetWord).where(DatasetWord.id == word_id).options(selectinload(DatasetWord.samples)))
    assert saved is not None
    return saved


@router.post("/dataset/words", response_model=DatasetWordOut, status_code=status.HTTP_201_CREATED, tags=[TAG])
async def create_word(body: AdminDatasetWordIn, admin: Staff, db: DB) -> DatasetWord:
    return await _save_word(db, DatasetWord(proposed_by_id=admin.id), body)


@router.put("/dataset/words/{word_id}", response_model=DatasetWordOut, tags=[TAG])
async def update_word(word_id: int, body: AdminDatasetWordIn, db: DB) -> DatasetWord:
    """Also used to approve or reject a proposed word (status)."""
    return await _save_word(db, await get_or_404(db, DatasetWord, word_id, "Word"), body)


@router.delete("/dataset/words/{word_id}", status_code=status.HTTP_204_NO_CONTENT, tags=[TAG])
async def delete_word(word_id: int, db: DB) -> Response:
    await db.delete(await get_or_404(db, DatasetWord, word_id, "Word"))
    await commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== recordings =====
@router.get("/dataset/contributions", response_model=Page[ContributionOut], tags=[TAG])
async def list_contributions(
    db: DB,
    status_: ReviewStatus | None = Query(default="pending", alias="status"),
    word_id: int | None = Query(default=None, alias="wordId"),
    user_id: int | None = Query(default=None, alias="userId"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> Page[ContributionOut]:
    where = []
    if status_:
        where.append(Contribution.status == status_)
    if word_id is not None:
        where.append(Contribution.word_id == word_id)
    if user_id is not None:
        where.append(Contribution.user_id == user_id)
    total = await db.scalar(select(func.count()).select_from(Contribution).where(*where)) or 0
    rows = await db.scalars(select(Contribution).where(*where).order_by(Contribution.created_at).limit(limit).offset(offset))
    return Page(items=[ContributionOut.model_validate(c) for c in rows], total=total)


@router.post("/dataset/contributions/{contribution_id}/review", response_model=ContributionOut, tags=[TAG])
async def review(contribution_id: int, body: ReviewIn, admin: Staff, db: DB) -> Contribution:
    contribution = await get_or_404(db, Contribution, contribution_id, "Contribution")
    if body.status == "rejected" and not body.rejection_reason:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Say why the recording is rejected")
    contribution.status = body.status
    contribution.rejection_reason = body.rejection_reason if body.status == "rejected" else None
    contribution.reviewed_by_id = admin.id
    contribution.reviewed_at = datetime.now(UTC)
    await commit(db)
    await db.refresh(contribution)
    return contribution


# ===== quick phrases for everyone =====
@router.get("/quick-phrases", response_model=list[QuickPhraseOut], tags=[TAG])
async def list_phrases(db: DB) -> list[QuickPhrase]:
    return list(await db.scalars(select(QuickPhrase).where(QuickPhrase.user_id.is_(None)).order_by(QuickPhrase.order, QuickPhrase.id)))


@router.post("/quick-phrases", response_model=QuickPhraseOut, status_code=status.HTTP_201_CREATED, tags=[TAG])
async def create_phrase(body: QuickPhraseIn, db: DB) -> QuickPhrase:
    phrase = QuickPhrase(user_id=None, **body.model_dump())
    db.add(phrase)
    await commit(db)
    await db.refresh(phrase)
    return phrase


async def _global_phrase(db: DB, phrase_id: int) -> QuickPhrase:
    phrase = await db.get(QuickPhrase, phrase_id)
    if phrase is None or phrase.user_id is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Phrase not found")
    return phrase


@router.put("/quick-phrases/{phrase_id}", response_model=QuickPhraseOut, tags=[TAG])
async def update_phrase(phrase_id: int, body: QuickPhraseIn, db: DB) -> QuickPhrase:
    phrase = await _global_phrase(db, phrase_id)
    phrase.text, phrase.order = body.text, body.order
    await commit(db)
    await db.refresh(phrase)
    return phrase


@router.delete("/quick-phrases/{phrase_id}", status_code=status.HTTP_204_NO_CONTENT, tags=[TAG])
async def delete_phrase(phrase_id: int, db: DB) -> Response:
    await db.delete(await _global_phrase(db, phrase_id))
    await commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)

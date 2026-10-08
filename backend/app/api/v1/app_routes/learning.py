import random
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, BackgroundTasks, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import selectinload

from app.api.v1.common import first_video
from app.core.config import get_settings
from app.deps import DB, CurrentUser, OptionalUser
from app.grading import grade
from app.models import (
    Course,
    Exercise,
    ExerciseAnswer,
    ExerciseReport,
    Lesson,
    LessonAttempt,
    LessonSign,
    Sign,
    User,
    UserLessonProgress,
)
from app.push import push_pending
from app.progress import add_daily, get_stats, learn_lesson_signs, level_for, record_session, stats_out, unlock_achievements, user_tz
from app.schemas.learning import (
    AnswerIn,
    BuiltinResultIn,
    AnswerOut,
    AttemptOut,
    CourseOut,
    ExerciseOut,
    FinishOut,
    LessonDetailOut,
    LessonOut,
    LessonSignOut,
    OptionOut,
    ReportIn,
    ReportOut,
)
from app.schemas.users import AchievementOut

router = APIRouter()

PUBLISHED_LESSON = (Lesson.is_published.is_(True), Course.is_published.is_(True))


async def _lesson_counts(db: DB, lesson_ids: list[int]) -> tuple[dict[int, int], dict[int, int]]:
    signs = dict((await db.execute(
        select(LessonSign.lesson_id, func.count()).where(LessonSign.lesson_id.in_(lesson_ids)).group_by(LessonSign.lesson_id)
    )).all())
    exercises = dict((await db.execute(
        select(Exercise.lesson_id, func.count()).where(Exercise.lesson_id.in_(lesson_ids)).group_by(Exercise.lesson_id)
    )).all())
    return signs, exercises


async def _progress(db: DB, user: User | None, lesson_ids: list[int]) -> dict[int, UserLessonProgress]:
    if user is None or not lesson_ids:
        return {}
    rows = await db.scalars(
        select(UserLessonProgress).where(UserLessonProgress.user_id == user.id, UserLessonProgress.lesson_id.in_(lesson_ids))
    )
    return {p.lesson_id: p for p in rows}


async def _lessons_out(db: DB, user: User | None, lessons: list[Lesson]) -> list[LessonOut]:
    ids = [lesson.id for lesson in lessons]
    signs, exercises = await _lesson_counts(db, ids)
    progress = await _progress(db, user, ids)
    out = []
    for lesson in lessons:
        p = progress.get(lesson.id)
        out.append(
            LessonOut.model_validate(lesson).model_copy(
                update={
                    "sign_count": signs.get(lesson.id, 0),
                    "exercise_count": exercises.get(lesson.id, 0),
                    "status": p.status if p else None,
                    "best_accuracy": p.best_accuracy if p else (0 if user else None),
                }
            )
        )
    return out


async def _published_lesson(db: DB, lesson_id: int) -> Lesson:
    lesson = await db.scalar(select(Lesson).join(Course).where(Lesson.id == lesson_id, *PUBLISHED_LESSON))
    if lesson is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Lesson not found")
    return lesson


# ===== courses and lessons =====
@router.get("/courses", response_model=list[CourseOut])
async def list_courses(db: DB, user: OptionalUser) -> list[CourseOut]:
    courses = list(await db.scalars(select(Course).where(Course.is_published.is_(True)).order_by(Course.order, Course.id)))
    lesson_counts = dict((await db.execute(
        select(Lesson.course_id, func.count()).where(Lesson.is_published.is_(True)).group_by(Lesson.course_id)
    )).all())
    completed: dict[int, int] = {}
    if user:
        completed = dict((await db.execute(
            select(Lesson.course_id, func.count())
            .join(UserLessonProgress, UserLessonProgress.lesson_id == Lesson.id)
            .where(UserLessonProgress.user_id == user.id, UserLessonProgress.status == "completed", Lesson.is_published.is_(True))
            .group_by(Lesson.course_id)
        )).all())
    return [
        CourseOut.model_validate(c).model_copy(
            update={"lesson_count": lesson_counts.get(c.id, 0), "completed_lessons": completed.get(c.id, 0) if user else None}
        )
        for c in courses
    ]


@router.get("/courses/{course_id}/lessons", response_model=list[LessonOut])
async def list_lessons(course_id: int, db: DB, user: OptionalUser) -> list[LessonOut]:
    course = await db.get(Course, course_id)
    if course is None or not course.is_published:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Course not found")
    lessons = list(await db.scalars(
        select(Lesson).where(Lesson.course_id == course_id, Lesson.is_published.is_(True)).order_by(Lesson.order, Lesson.id)
    ))
    return await _lessons_out(db, user, lessons)


@router.get("/lessons/{lesson_id}", response_model=LessonDetailOut)
async def get_lesson(lesson_id: int, db: DB, user: OptionalUser) -> LessonDetailOut:
    """The lesson with its signs and exercises. Correct answers are not included; send answers to an attempt."""
    await _published_lesson(db, lesson_id)
    lesson = await db.scalar(
        select(Lesson)
        .where(Lesson.id == lesson_id)
        .options(
            selectinload(Lesson.signs).selectinload(Sign.videos),
            selectinload(Lesson.exercises).selectinload(Exercise.options),
        )
    )
    assert lesson is not None

    # Videos for every sign the exercises show
    sign_ids = {e.sign_id for e in lesson.exercises} | {o.sign_id for e in lesson.exercises for o in e.options}
    sign_ids.discard(None)
    signs = {s.id: s for s in await db.scalars(select(Sign).where(Sign.id.in_(sign_ids)).options(selectinload(Sign.videos)))}

    exercises = []
    for e in lesson.exercises:
        options = [
            OptionOut.model_validate(o).model_copy(update={"sign_video": first_video(signs.get(o.sign_id))})
            for o in e.options
        ]
        if e.type in ("order", "matching"):
            random.shuffle(options)
        exercises.append(
            ExerciseOut(
                id=e.id, type=e.type, prompt=e.prompt, prompt_ru=e.prompt_ru, prompt_en=e.prompt_en, sign_id=e.sign_id,
                sign_video=first_video(signs.get(e.sign_id)), order=e.order, options=options,
            )
        )

    [base] = await _lessons_out(db, user, [lesson])
    return LessonDetailOut(
        **base.model_dump(),
        signs=[LessonSignOut.model_validate(s) for s in lesson.signs],
        exercises=exercises,
    )


# ===== attempts =====
async def _own_attempt(db: DB, user: User, attempt_id: int) -> LessonAttempt:
    attempt = await db.get(LessonAttempt, attempt_id)
    if attempt is None or attempt.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Attempt not found")
    if attempt.finished_at is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "This attempt is already finished")
    return attempt


@router.post("/lessons/{lesson_id}/attempts", response_model=AttemptOut, status_code=status.HTTP_201_CREATED)
async def start_attempt(lesson_id: int, user: CurrentUser, db: DB) -> LessonAttempt:
    await _published_lesson(db, lesson_id)
    attempt = LessonAttempt(user_id=user.id, lesson_id=lesson_id)
    db.add(attempt)
    await db.execute(insert(UserLessonProgress).values(user_id=user.id, lesson_id=lesson_id).on_conflict_do_nothing())
    await db.commit()
    await db.refresh(attempt)
    return attempt


@router.post("/attempts/{attempt_id}/answers", response_model=AnswerOut)
async def answer(attempt_id: int, body: AnswerIn, user: CurrentUser, db: DB) -> AnswerOut:
    attempt = await _own_attempt(db, user, attempt_id)
    exercise = await db.scalar(
        select(Exercise).where(Exercise.id == body.exercise_id).options(selectinload(Exercise.options))
    )
    if exercise is None or exercise.lesson_id != attempt.lesson_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Exercise not found in this lesson")
    if await db.scalar(select(ExerciseAnswer.id).where(ExerciseAnswer.attempt_id == attempt.id, ExerciseAnswer.exercise_id == exercise.id)):
        raise HTTPException(status.HTTP_409_CONFLICT, "This exercise is already answered")

    result = grade(exercise, body.answer)
    db.add(ExerciseAnswer(attempt_id=attempt.id, exercise_id=exercise.id, answer=body.answer, is_correct=result.is_correct))
    await db.commit()
    return AnswerOut(
        is_correct=result.is_correct,
        explanation=exercise.explanation,
        explanation_ru=exercise.explanation_ru,
        explanation_en=exercise.explanation_en,
        correct_option_id=result.correct_option_id,
        correct_order=result.correct_order,
    )


async def _complete(
    db: DB, user: User, lesson: Lesson, attempt: LessonAttempt, correct: int, total: int, background: BackgroundTasks
) -> FinishOut:
    """Scores a finished attempt: progress, XP, level, streak, learned signs, achievements, push."""
    now = datetime.now(UTC)
    accuracy = round(correct * 100 / total) if total else 100
    passed = accuracy >= get_settings().lesson_pass_accuracy

    progress = await db.scalar(
        select(UserLessonProgress).where(UserLessonProgress.user_id == user.id, UserLessonProgress.lesson_id == lesson.id)
    )
    if progress is None:
        progress = UserLessonProgress(user_id=user.id, lesson_id=lesson.id, best_accuracy=0)
        db.add(progress)
    previous_best = progress.best_accuracy or 0

    # XP only for doing better than before, so repeating a lesson can't farm XP
    xp = 0
    if passed:
        xp = max(0, round(lesson.xp_reward * accuracy / 100) - round(lesson.xp_reward * previous_best / 100))
        if progress.status != "completed":
            progress.status = "completed"
            progress.completed_at = now
    progress.best_accuracy = max(previous_best, accuracy)

    attempt.finished_at = now
    attempt.correct_count = correct
    attempt.total_count = total
    attempt.accuracy = accuracy
    attempt.xp_earned = xp

    session = await record_session(db, user, "lesson", attempt.started_at, now)
    attempt.duration_seconds = session.duration_seconds
    today = now.astimezone(user_tz(user)).date()
    await add_daily(
        db, user.id, today, xp=xp, lessons_completed=int(passed), correct_answers=correct, total_answers=total
    )

    stats = await get_stats(db, user.id)
    stats.total_xp += xp
    stats.level = level_for(stats.total_xp)
    if passed:
        stats.signs_learned = await learn_lesson_signs(db, user.id, lesson.id)
    await db.flush()
    unlocked = await unlock_achievements(db, user, stats)
    await db.commit()
    push_pending(db, background)

    return FinishOut(
        attempt=AttemptOut.model_validate(attempt),
        passed=passed,
        status=progress.status,
        best_accuracy=progress.best_accuracy,
        stats=await stats_out(db, user),
        unlocked_achievements=[AchievementOut.model_validate(a).model_copy(update={"unlocked_at": at}) for a, at in unlocked],
    )


@router.post("/attempts/{attempt_id}/finish", response_model=FinishOut)
async def finish(attempt_id: int, user: CurrentUser, db: DB, background: BackgroundTasks) -> FinishOut:
    attempt = await _own_attempt(db, user, attempt_id)
    lesson = await db.get(Lesson, attempt.lesson_id)
    assert lesson is not None
    # Exercises left unanswered count as wrong
    total = await db.scalar(select(func.count()).where(Exercise.lesson_id == lesson.id)) or 0
    correct = await db.scalar(
        select(func.count()).where(ExerciseAnswer.attempt_id == attempt.id, ExerciseAnswer.is_correct.is_(True))
    ) or 0
    return await _complete(db, user, lesson, attempt, correct, total, background)


# ===== the app's built-in lessons =====
# Lesson ids used by the app's own lesson screens ("alp_0") -> textbook slug; the number is the lesson's place
BUILTIN_TEXTBOOKS = {"alp": "alphabet", "num": "numbers", "fam": "family", "eat": "food", "feel": "feelings"}


@router.get("/builtin-lessons/completed", response_model=list[str])
async def completed_builtin_lessons(user: CurrentUser, db: DB) -> list[str]:
    """Built-in lessons ("alp_0", ...) this account has completed, so a phone can show the account's progress."""
    prefix_of = {slug: prefix for prefix, slug in BUILTIN_TEXTBOOKS.items()}
    place = (
        func.row_number().over(partition_by=Lesson.course_id, order_by=(Lesson.order, Lesson.id)) - 1
    ).label("place")
    lessons = (
        select(Lesson.id, Course.slug, place)
        .join(Course)
        .where(Course.slug.in_(prefix_of), *PUBLISHED_LESSON)
        .subquery()
    )
    rows = await db.execute(
        select(lessons.c.slug, lessons.c.place)
        .join(UserLessonProgress, UserLessonProgress.lesson_id == lessons.c.id)
        .where(UserLessonProgress.user_id == user.id, UserLessonProgress.status == "completed")
    )
    return [f"{prefix_of[slug]}_{place}" for slug, place in rows.all()]


async def _builtin_lesson(db: DB, key: str) -> Lesson:
    """The published lesson behind a built-in lesson id: "alp_0" = the first Alphabet lesson."""
    prefix, _, number = key.partition("_")
    slug = BUILTIN_TEXTBOOKS.get(prefix)
    lesson = None
    if slug is not None and number.isdigit():
        lesson = await db.scalar(
            select(Lesson)
            .join(Course)
            .where(Course.slug == slug, *PUBLISHED_LESSON)
            .order_by(Lesson.order, Lesson.id)
            .offset(int(number))
            .limit(1)
        )
    if lesson is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Unknown lesson")
    return lesson


@router.get("/builtin-lessons/{key}", response_model=LessonOut)
async def builtin_lesson(key: str, db: DB, user: OptionalUser) -> LessonOut:
    """
    The database lesson for a built-in lesson ("alp_0"). When it has exercises (made or edited in the
    dashboard), the app plays it from here instead of its own screens.
    """
    [out] = await _lessons_out(db, user, [await _builtin_lesson(db, key)])
    return out


@router.post("/builtin-lessons/{key}/complete", response_model=FinishOut)
async def complete_builtin_lesson(
    key: str, body: BuiltinResultIn, user: CurrentUser, db: DB, background: BackgroundTasks
) -> FinishOut:
    """
    Result of a lesson that the app plays with its own screens (its exercises are not in the database):
    the app sends how many answers were right and wrong, and the result counts like any other lesson.
    """
    lesson = await _builtin_lesson(db, key)
    now = datetime.now(UTC)
    attempt = LessonAttempt(user_id=user.id, lesson_id=lesson.id, started_at=now - timedelta(seconds=body.duration_seconds))
    db.add(attempt)
    await db.flush()
    return await _complete(db, user, lesson, attempt, body.correct, body.correct + body.wrong, background)


@router.post("/exercises/{exercise_id}/reports", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
async def report_exercise(exercise_id: int, body: ReportIn, user: CurrentUser, db: DB) -> ExerciseReport:
    if await db.get(Exercise, exercise_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Exercise not found")
    report = ExerciseReport(user_id=user.id, exercise_id=exercise_id, reason=body.reason, comment=body.comment)
    db.add(report)
    await db.commit()
    await db.refresh(report)
    return report

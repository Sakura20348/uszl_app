from typing import Literal

from fastapi import APIRouter, HTTPException, Query, Response, status
from sqlalchemy import delete, func, select
from sqlalchemy.orm import selectinload

from app.api.v1.common import commit, crud_routes, get_or_404
from app.deps import DB
from app.models import Achievement, Course, Exercise, ExerciseOption, ExerciseReport, Lesson, LessonSign, Sign, User
from app.schemas.admin import AchievementIn, AdminReportOut, ReportUpdate
from app.schemas.common import Page
from app.schemas.learning import (
    AdminExerciseOut,
    CourseIn,
    CourseOut,
    ExercisesIn,
    LessonIn,
    LessonOut,
)
from app.schemas.users import AchievementOut

router = APIRouter()
TAG = "admin: learning"

crud_routes(router, "/achievements", Achievement, AchievementIn, AchievementOut, (Achievement.order, Achievement.id), TAG)


# ===== courses =====
async def _course_out(db: DB, courses: list[Course]) -> list[CourseOut]:
    counts = dict((await db.execute(
        select(Lesson.course_id, func.count()).where(Lesson.course_id.in_([c.id for c in courses])).group_by(Lesson.course_id)
    )).all())
    return [CourseOut.model_validate(c).model_copy(update={"lesson_count": counts.get(c.id, 0)}) for c in courses]


@router.get("/courses", response_model=list[CourseOut], tags=[TAG])
async def list_courses(db: DB) -> list[CourseOut]:
    return await _course_out(db, list(await db.scalars(select(Course).order_by(Course.order, Course.id))))


@router.post("/courses", response_model=CourseOut, status_code=status.HTTP_201_CREATED, tags=[TAG])
async def create_course(body: CourseIn, db: DB) -> CourseOut:
    course = Course(**body.model_dump())
    db.add(course)
    await commit(db)
    await db.refresh(course)
    return (await _course_out(db, [course]))[0]


@router.put("/courses/{course_id}", response_model=CourseOut, tags=[TAG])
async def update_course(course_id: int, body: CourseIn, db: DB) -> CourseOut:
    course = await get_or_404(db, Course, course_id, "Course")
    for field, value in body.model_dump().items():
        setattr(course, field, value)
    await commit(db)
    await db.refresh(course)
    return (await _course_out(db, [course]))[0]


@router.delete("/courses/{course_id}", status_code=status.HTTP_204_NO_CONTENT, tags=[TAG])
async def delete_course(course_id: int, db: DB) -> Response:
    """Also deletes its lessons, exercises and the learners' progress in them."""
    await db.delete(await get_or_404(db, Course, course_id, "Course"))
    await commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== lessons =====
async def _lessons_out(db: DB, lessons: list[Lesson]) -> list[LessonOut]:
    ids = [lesson.id for lesson in lessons]
    signs = dict((await db.execute(
        select(LessonSign.lesson_id, func.count()).where(LessonSign.lesson_id.in_(ids)).group_by(LessonSign.lesson_id)
    )).all())
    exercises = dict((await db.execute(
        select(Exercise.lesson_id, func.count()).where(Exercise.lesson_id.in_(ids)).group_by(Exercise.lesson_id)
    )).all())
    return [
        LessonOut.model_validate(lesson).model_copy(
            update={"sign_count": signs.get(lesson.id, 0), "exercise_count": exercises.get(lesson.id, 0)}
        )
        for lesson in lessons
    ]


@router.get("/courses/{course_id}/lessons", response_model=list[LessonOut], tags=[TAG])
async def list_lessons(course_id: int, db: DB) -> list[LessonOut]:
    await get_or_404(db, Course, course_id, "Course")
    lessons = list(await db.scalars(select(Lesson).where(Lesson.course_id == course_id).order_by(Lesson.order, Lesson.id)))
    return await _lessons_out(db, lessons)


@router.get("/lessons/{lesson_id}/sign-ids", response_model=list[int], tags=[TAG])
async def lesson_sign_ids(lesson_id: int, db: DB) -> list[int]:
    await get_or_404(db, Lesson, lesson_id, "Lesson")
    return list(await db.scalars(select(LessonSign.sign_id).where(LessonSign.lesson_id == lesson_id).order_by(LessonSign.order)))


async def _save_lesson(db: DB, lesson: Lesson, body: LessonIn) -> LessonOut:
    await get_or_404(db, Course, body.course_id, "Course")
    sign_ids = None if body.sign_ids is None else list(dict.fromkeys(body.sign_ids))
    if sign_ids:
        found = set(await db.scalars(select(Sign.id).where(Sign.id.in_(sign_ids))))
        if missing := set(sign_ids) - found:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, f"Unknown sign ids: {sorted(missing)}")
    for field, value in body.model_dump(exclude={"sign_ids"}).items():
        setattr(lesson, field, value)
    db.add(lesson)
    await db.flush()
    if sign_ids is not None:
        await db.execute(delete(LessonSign).where(LessonSign.lesson_id == lesson.id))
        db.add_all(LessonSign(lesson_id=lesson.id, sign_id=s, order=i) for i, s in enumerate(sign_ids))
    await commit(db)
    await db.refresh(lesson)
    return (await _lessons_out(db, [lesson]))[0]


@router.post("/lessons", response_model=LessonOut, status_code=status.HTTP_201_CREATED, tags=[TAG])
async def create_lesson(body: LessonIn, db: DB) -> LessonOut:
    return await _save_lesson(db, Lesson(), body)


@router.put("/lessons/{lesson_id}", response_model=LessonOut, tags=[TAG])
async def update_lesson(lesson_id: int, body: LessonIn, db: DB) -> LessonOut:
    return await _save_lesson(db, await get_or_404(db, Lesson, lesson_id, "Lesson"), body)


@router.delete("/lessons/{lesson_id}", status_code=status.HTTP_204_NO_CONTENT, tags=[TAG])
async def delete_lesson(lesson_id: int, db: DB) -> Response:
    await db.delete(await get_or_404(db, Lesson, lesson_id, "Lesson"))
    await commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ===== exercises (lesson builder) =====
async def _exercises(db: DB, lesson_id: int) -> list[Exercise]:
    db.expire_all()
    return list(await db.scalars(
        select(Exercise).where(Exercise.lesson_id == lesson_id).options(selectinload(Exercise.options)).order_by(Exercise.order, Exercise.id)
    ))


@router.get("/lessons/{lesson_id}/exercises", response_model=list[AdminExerciseOut], tags=[TAG])
async def get_exercises(lesson_id: int, db: DB) -> list[Exercise]:
    await get_or_404(db, Lesson, lesson_id, "Lesson")
    return await _exercises(db, lesson_id)


@router.put("/lessons/{lesson_id}/exercises", response_model=list[AdminExerciseOut], tags=[TAG])
async def save_exercises(lesson_id: int, body: ExercisesIn, db: DB) -> list[Exercise]:
    """
    Replaces all exercises of the lesson, like saving in the lesson builder.
    Answers and reports on the old exercises are removed with them.
    """
    await get_or_404(db, Lesson, lesson_id, "Lesson")
    sign_ids = {e.sign_id for e in body.exercises} | {o.sign_id for e in body.exercises for o in e.options}
    sign_ids.discard(None)
    found = set(await db.scalars(select(Sign.id).where(Sign.id.in_(sign_ids))))
    if missing := sign_ids - found:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, f"Unknown sign ids: {sorted(missing)}")

    await db.execute(delete(Exercise).where(Exercise.lesson_id == lesson_id))
    for i, e in enumerate(body.exercises):
        exercise = Exercise(
            lesson_id=lesson_id, order=i, **e.model_dump(exclude={"options"}),
            options=[ExerciseOption(**o.model_dump()) for o in e.options],
        )
        db.add(exercise)
    await commit(db)
    return await _exercises(db, lesson_id)


# ===== reports =====
def _reports_query():
    """Reports with their exercise, lesson, course and the learner who sent them."""
    return (
        select(
            ExerciseReport,
            Exercise.type, Exercise.prompt, Lesson.id, Lesson.title, Course.id, Course.title, User.full_name, User.phone,
        )
        .join(Exercise, Exercise.id == ExerciseReport.exercise_id)
        .join(Lesson, Lesson.id == Exercise.lesson_id)
        .join(Course, Course.id == Lesson.course_id)
        .outerjoin(User, User.id == ExerciseReport.user_id)
    )


def _report_out(row) -> AdminReportOut:
    report, ex_type, prompt, lesson_id, lesson_title, course_id, course_title, name, phone = row
    return AdminReportOut(
        id=report.id, exercise_id=report.exercise_id, reason=report.reason, comment=report.comment,
        status=report.status, created_at=report.created_at, exercise_type=ex_type, exercise_prompt=prompt,
        lesson_id=lesson_id, lesson_title=lesson_title, course_id=course_id, course_title=course_title,
        user_id=report.user_id, user_name=name or phone,
    )


@router.get("/reports", response_model=Page[AdminReportOut], tags=[TAG])
async def list_reports(
    db: DB,
    status_: Literal["new", "reviewed", "fixed", "rejected"] | None = Query(default=None, alias="status"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> Page[AdminReportOut]:
    where = [ExerciseReport.status == status_] if status_ else []
    total = await db.scalar(select(func.count()).select_from(ExerciseReport).where(*where)) or 0
    rows = await db.execute(
        _reports_query().where(*where).order_by(ExerciseReport.created_at.desc(), ExerciseReport.id.desc()).limit(limit).offset(offset)
    )
    return Page(items=[_report_out(r) for r in rows.all()], total=total)


@router.patch("/reports/{report_id}", response_model=AdminReportOut, tags=[TAG])
async def update_report(report_id: int, body: ReportUpdate, db: DB) -> AdminReportOut:
    report = await get_or_404(db, ExerciseReport, report_id, "Report")
    report.status = body.status
    await commit(db)
    return _report_out((await db.execute(_reports_query().where(ExerciseReport.id == report_id))).one())

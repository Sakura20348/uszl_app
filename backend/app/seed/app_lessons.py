"""Puts the content of the app's built-in lessons into the database, so the dashboard shows it:

    uv run python -m app.seed.app_lessons [--videos ../assets/videos]

For each lesson in app_lessons.json (made by scripts/extract_app_lessons.py):
- its words become dictionary signs (an existing sign with the same word in the category is reused),
  with the app's video copied to MEDIA_DIR/signs/app/...
- the signs are linked to the lesson (lesson_signs)
- lessons whose signs have videos get exercises like the app's: watch the video and pick the
  letter/number/word, and one "match the videos" exercise

Safe to run again: lessons that already have signs or exercises are left as they are.
"""

import argparse
import asyncio
import json
import random
import shutil
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from app.core.config import get_settings
from app.db import SessionLocal
from app.models import Category, Course, Exercise, ExerciseOption, Lesson, LessonSign, Sign, SignCategory, SignVideo

DATA = json.loads((Path(__file__).parent / "app_lessons.json").read_text(encoding="utf-8"))
DEFAULT_VIDEOS = Path(__file__).resolve().parents[3] / "assets" / "videos"

# Exercise questions, in Uzbek like the app's lessons
QUESTION = {"letter": "Bu qaysi harf?", "number": "Bu qaysi raqam?", "word": "Bu qaysi soʻz?"}
MATCHING = "Videolarni toʻgʻri javob bilan moslang"
OPTIONS = 4


async def lesson_at(db, course: Course, place: int) -> Lesson | None:
    """The course's lesson at this place (0 = first), the way the app counts them."""
    return await db.scalar(
        select(Lesson).where(Lesson.course_id == course.id).order_by(Lesson.order, Lesson.id).offset(place).limit(1)
    )


async def find_or_create_sign(db, word: dict, category: Category, videos_dir: Path, media_dir: Path, stats: dict) -> Sign:
    sign = await db.scalar(
        select(Sign)
        .where(func.lower(Sign.word) == word["word"].lower(), Sign.categories.any(Category.id == category.id))
        .options(selectinload(Sign.videos))
    )
    if sign is None:
        sign = Sign(
            word=word["word"], translation_ru=word["translationRu"], translation_en=word["translationEn"], kind=word["kind"]
        )
        db.add(sign)
        await db.flush()
        db.add(SignCategory(sign_id=sign.id, category_id=category.id))
        await db.refresh(sign, ["videos"])
        stats["signs"] += 1
    else:
        stats["reused"] += 1

    if word["video"] and not any(v.angle == "front" for v in sign.videos):
        source = videos_dir / word["video"]
        if source.exists():
            # Stored path must fit the varchar(100) file columns
            relative = f"signs/app/{word['video']}"
            target = media_dir / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            db.add(SignVideo(sign_id=sign.id, video=relative, angle="front"))
            stats["videos"] += 1
        else:
            stats["missing_videos"].append(word["video"])
    return sign


def make_exercises(lesson: Lesson, signs: list[Sign], with_video: set[int], pool: list[str]) -> list[Exercise]:
    """Watch a video, pick the right answer (one per sign with a video), then match up to four videos."""
    rng = random.Random(lesson.id)
    video_signs = [s for s in signs if s.id in with_video]
    exercises = []
    for sign in video_signs:
        others = [w for w in dict.fromkeys(s.word for s in signs) if w != sign.word]
        if len(others) < OPTIONS - 1:
            others += [w for w in pool if w != sign.word and w not in others]
        choices = rng.sample(others, OPTIONS - 1) + [sign.word]
        rng.shuffle(choices)
        exercises.append(
            Exercise(
                lesson_id=lesson.id, type="chooseText", prompt=QUESTION.get(sign.kind, QUESTION["word"]), sign_id=sign.id,
                order=len(exercises),
                options=[ExerciseOption(text=c, is_correct=c == sign.word) for c in choices],
            )
        )
    if len(video_signs) >= 2:
        pairs = rng.sample(video_signs, min(4, len(video_signs)))
        exercises.append(
            Exercise(
                lesson_id=lesson.id, type="matching", prompt=MATCHING, order=len(exercises),
                options=[ExerciseOption(text=s.word, sign_id=s.id, is_correct=True, position=i) for i, s in enumerate(pairs)],
            )
        )
    return exercises


async def main(videos_dir: Path) -> None:
    media_dir = Path(get_settings().media_dir)
    stats = {"signs": 0, "reused": 0, "videos": 0, "lessons": 0, "exercises": 0, "missing_videos": [], "skipped": []}
    async with SessionLocal() as db:
        courses = {c.slug: c for c in await db.scalars(select(Course))}
        categories = {c.slug: c for c in await db.scalars(select(Category))}
        # Wrong answers come from the same textbook's words
        pools = {}
        for lesson_data in DATA["lessons"]:
            pools.setdefault(lesson_data["course"], []).extend(w["word"] for w in lesson_data["words"])

        for lesson_data in DATA["lessons"]:
            course = courses.get(lesson_data["course"])
            category = categories.get(lesson_data["course"])
            lesson = await lesson_at(db, course, lesson_data["place"]) if course else None
            if lesson is None or category is None:
                stats["skipped"].append(lesson_data["key"])
                continue

            signs = []
            with_video = set()
            for word in lesson_data["words"]:
                sign = await find_or_create_sign(db, word, category, videos_dir, media_dir, stats)
                signs.append(sign)
                await db.flush()
                if await db.scalar(select(func.count()).where(SignVideo.sign_id == sign.id)):
                    with_video.add(sign.id)

            if not await db.scalar(select(func.count()).where(LessonSign.lesson_id == lesson.id)):
                for i, sign in enumerate(dict.fromkeys(signs)):
                    db.add(LessonSign(lesson_id=lesson.id, sign_id=sign.id, order=i))
                stats["lessons"] += 1

            if not await db.scalar(select(func.count()).where(Exercise.lesson_id == lesson.id)):
                exercises = make_exercises(lesson, list(dict.fromkeys(signs)), with_video, list(dict.fromkeys(pools[lesson_data["course"]])))
                db.add_all(exercises)
                stats["exercises"] += len(exercises)
            await db.flush()

        await db.commit()

    print(
        f"signs: {stats['signs']} new, {stats['reused']} reused; videos copied: {stats['videos']}; "
        f"lessons filled: {stats['lessons']}; exercises made: {stats['exercises']}"
    )
    if stats["missing_videos"]:
        print(f"videos not found in {videos_dir}: {stats['missing_videos']}")
    if stats["skipped"]:
        print(f"skipped (no such lesson or category in the database): {stats['skipped']}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog="python -m app.seed.app_lessons")
    parser.add_argument("--videos", type=Path, default=DEFAULT_VIDEOS, help="the app's assets/videos folder")
    asyncio.run(main(parser.parse_args().videos))

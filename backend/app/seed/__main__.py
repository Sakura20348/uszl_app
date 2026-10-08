"""Fills an empty database with starter content:

    uv run python -m app.seed

- courses and lessons: the textbooks and lesson cards of the mobile app (as they were in the dashboard)
- categories and sample signs: from the dashboard's dictionary
- achievements: the 10 achievements of the mobile app (lib/services/achievement_service.dart)

Each part is skipped if its table already has rows, so it is safe to run again.
"""

import asyncio
import json
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import SessionLocal
from app.models import Achievement, Category, Course, Lesson, Sign, SignCategory, SignRelated

DATA = json.loads((Path(__file__).parent / "data.json").read_text(encoding="utf-8"))


async def _empty(db: AsyncSession, model: type) -> bool:
    return not await db.scalar(select(func.count()).select_from(model))


async def seed_courses(db: AsyncSession) -> None:
    if not await _empty(db, Course):
        print("courses: already filled, skipped")
        return
    for c in DATA["courses"]:
        fields = {k: v for k, v in c.items() if k != "lessons"}
        db.add(Course(**fields, lessons=[Lesson(**lesson) for lesson in c["lessons"]]))
    print(f"courses: added {len(DATA['courses'])}, with {sum(len(c['lessons']) for c in DATA['courses'])} lessons")


async def seed_dictionary(db: AsyncSession) -> None:
    if await _empty(db, Category):
        db.add_all(Category(**c) for c in DATA["categories"])
        await db.flush()
        print(f"categories: added {len(DATA['categories'])}")
    else:
        print("categories: already filled, skipped")

    if not await _empty(db, Sign):
        print("signs: already filled, skipped")
        return
    categories = {c.slug: c.id for c in await db.scalars(select(Category))}
    by_key: dict[int, Sign] = {}
    for s in DATA["signs"]:
        fields = {k: v for k, v in s.items() if k not in ("key", "categories", "related")}
        by_key[s["key"]] = sign = Sign(**fields)
        db.add(sign)
    await db.flush()
    for s in DATA["signs"]:
        sign = by_key[s["key"]]
        db.add_all(SignCategory(sign_id=sign.id, category_id=categories[slug]) for slug in s["categories"] if slug in categories)
        db.add_all(SignRelated(from_sign_id=sign.id, to_sign_id=by_key[r].id) for r in s["related"] if r in by_key and r != s["key"])
    print(f"signs: added {len(DATA['signs'])}")


async def seed_achievements(db: AsyncSession) -> None:
    if not await _empty(db, Achievement):
        print("achievements: already filled, skipped")
        return
    courses = {c.slug: c.id for c in await db.scalars(select(Course))}
    for a in DATA["achievements"]:
        fields = {k: v for k, v in a.items() if k != "course_slug"}
        db.add(Achievement(**fields, course_id=courses.get(a["course_slug"]) if a["course_slug"] else None))
    print(f"achievements: added {len(DATA['achievements'])}")


async def main() -> None:
    async with SessionLocal() as db:
        await seed_courses(db)
        await db.flush()
        await seed_dictionary(db)
        await seed_achievements(db)
        await db.commit()


if __name__ == "__main__":
    asyncio.run(main())

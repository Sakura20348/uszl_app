"""Checks a learner's answer to an exercise. Answer formats are documented on schemas.learning.AnswerIn."""

from dataclasses import dataclass
from typing import Any

from app.models import Exercise


@dataclass
class Grade:
    is_correct: bool
    correct_option_id: int | None = None
    correct_order: list[int] | None = None


def _int_list(value: Any) -> list[int] | None:
    if not isinstance(value, list) or not all(isinstance(v, int) for v in value):
        return None
    return value


def grade(exercise: Exercise, answer: dict[str, Any]) -> Grade:
    options = exercise.options
    ids = {o.id for o in options}

    if exercise.type in ("chooseText", "chooseImage"):
        correct = next((o.id for o in options if o.is_correct), None)
        return Grade(is_correct=answer.get("optionId") == correct, correct_option_id=correct)

    if exercise.type == "matching":
        # Each pair must join an option's video/image with that same option's text
        pairs = answer.get("pairs")
        if not isinstance(pairs, list) or not all(_int_list(p) and len(p) == 2 for p in pairs):
            return Grade(is_correct=False)
        matched = {a for a, b in pairs if a == b and a in ids}
        return Grade(is_correct=len(pairs) == len(ids) and matched == ids)

    if exercise.type == "order":
        # Extra (wrong) words have no position and are not part of the answer
        correct_order = [o.id for o in sorted((o for o in options if o.position is not None), key=lambda o: o.position)]
        return Grade(is_correct=_int_list(answer.get("optionIds")) == correct_order, correct_order=correct_order)

    return Grade(is_correct=False)

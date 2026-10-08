"""Turns text into a sequence of dictionary signs."""

import re

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Sign

# Longest dictionary entry (in words) we try to match, e.g. "assalomu alaykum"
MAX_PHRASE_WORDS = 4
# Uzbek digraphs that have their own letter sign
DIGRAPHS = ("o'", "g'", "sh", "ch", "ng")

_APOSTROPHES = str.maketrans({"ʻ": "'", "ʼ": "'", "‘": "'", "’": "'", "`": "'"})


def normalize(text: str) -> str:
    return text.translate(_APOSTROPHES).lower().strip()


def tokenize(text: str) -> list[str]:
    return re.findall(r"[\w']+", normalize(text))


def letters_of(word: str) -> list[str]:
    out, i = [], 0
    while i < len(word):
        pair = word[i : i + 2]
        if pair in DIGRAPHS:
            out.append(pair)
            i += 2
        else:
            out.append(word[i])
            i += 1
    return [c for c in out if c != "'"]


async def text_to_signs(db: AsyncSession, text: str) -> list[Sign]:
    words = tokenize(text)
    if not words:
        return []

    # Every phrase of up to MAX_PHRASE_WORDS words that appears in the text
    candidates = {
        " ".join(words[i : i + n]) for i in range(len(words)) for n in range(1, MAX_PHRASE_WORDS + 1) if i + n <= len(words)
    }
    candidates |= {c for w in words for c in letters_of(w)}
    rows = await db.scalars(
        select(Sign)
        .where(Sign.is_published.is_(True), func.lower(func.translate(Sign.word, "ʻʼ‘’`", "'" * 5)).in_(candidates))
        .order_by(Sign.id)
    )
    words_index: dict[str, Sign] = {}
    letters_index: dict[str, Sign] = {}
    for sign in rows:
        key = normalize(sign.word)
        target = letters_index if sign.kind == "letter" else words_index
        target.setdefault(key, sign)

    result: list[Sign] = []
    i = 0
    while i < len(words):
        # Longest phrase first
        for n in range(min(MAX_PHRASE_WORDS, len(words) - i), 0, -1):
            sign = words_index.get(" ".join(words[i : i + n]))
            if sign:
                result.append(sign)
                i += n
                break
        else:
            # Unknown word: fingerspell it with letter signs
            result.extend(letters_index[c] for c in letters_of(words[i]) if c in letters_index)
            i += 1
    return result

"""Reads the words each built-in lesson of the mobile app teaches, with their videos, from the
app's Dart code and translations, and writes app/seed/app_lessons.json for `python -m app.seed.app_lessons`.

    uv run python scripts/extract_app_lessons.py [path/to/signlang]

The app's lessons are screens written in Dart; their word lists live in classes like
ZeroAndNineData in lib/components/uiTextBooks/nameTextbooks/. Alphabet lessons have no word list:
their letters come from the lesson names ("A – E").
"""

import json
import re
import sys
from pathlib import Path

APP = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parents[2])
OUT = Path(__file__).resolve().parents[1] / "app" / "seed" / "app_lessons.json"

LANG = {lang: json.loads((APP / "lang" / f"{lang}.json").read_text(encoding="utf-8")) for lang in ("uz", "ru", "en")}
SOURCE = "".join(
    (APP / "lib/components/uiTextBooks/nameTextbooks" / f).read_text(encoding="utf-8")
    for f in ("nameTextbooks.dart", "nameTextbooks2.dart")
)

# Lesson key -> the data classes with its words, in order (each lesson shows two lists of five)
NUMBERS = ["ZeroAndNine", "TenAndNineteen", "TwentyAndNumber", "TwoHundredAndThousand", "TwoThousandAndThird"]
FAMILY = ["FamAndChildren", "ChildAndBoy", "GirlAndCousin", "NieceAndSpouse", "DivorceAndPoor", "ToRespectAndTall", "LittleAndToDie"]
FOOD = ["FruitAndPomegranate", "SteamedDumplingsAndTea", "SweetTeaAndTenderFood", "FruitAndPomegranate", "FigAndVegetables",
        "OnionAndCabbage", "BeetrootAndBread", "SaltAndYoghurt", "KefirAndPancakes"]
LESSON_CLASSES = {
    **{f"num_{i}": [f"{n}Data", f"{n}2Data"] for i, n in enumerate(NUMBERS)},
    **{f"fam_{i}": [f"{n}Data", f"{n}2Data"] for i, n in enumerate(FAMILY)},
    # eat_0 is "Food" with one list; the others have two
    "eat_0": ["FoodAndSamosaData"],
    **{f"eat_{i}": [f"{n}Data", f"{n}2Data"] for i, n in enumerate(FOOD) if i > 0},
    # Only the first Feelings lesson has a word list, and its words have no texts in lang/*.json yet,
    # so it is skipped (no lesson gets added for it)
    "feel_0": ["FeelingsAndCoarseData", "FeelingsAndCoarse2Data"],
}
COURSE = {"alp": "alphabet", "num": "numbers", "fam": "family", "eat": "food", "feel": "feelings"}
KIND = {"alp": "letter", "num": "number"}

# Alphabet lessons and their letters (the app's alphabet has no C, W)
ALPHABET = {
    "alp_0": ["A", "B", "D", "E"], "alp_1": ["F", "G", "H", "I"], "alp_2": ["J", "K", "L", "M"],
    "alp_3": ["N", "O", "P", "Q"], "alp_4": ["R", "S", "T", "U"], "alp_5": ["V", "X", "Y", "Z"],
    "alp_6": ["Oʻ", "Gʻ", "Sh", "Ch"],
}
LETTER_VIDEO = {"Oʻ": "level_O_apos.mp4", "Gʻ": "level_G_apos.mp4", "O": "Level_O.mp4"}
VIDEOS = APP / "assets/videos"


NUMBER_WORDS = {
    "number_first_symbol": {"uz": "Birinchi", "ru": "Первый", "en": "first"},
    "number_second_symbol": {"uz": "Ikkinchi", "ru": "Второй", "en": "second"},
    "number_third_symbol": {"uz": "Uchinchi", "ru": "Третий", "en": "third"},
    "number_symbol": {"uz": "Raqam", "ru": "Число", "en": "number"},
    "thousand_symbol": {"uz": "Ming", "ru": "Тысяча", "en": "thousand"},
}
# The app links these videos by names that don't exist in assets/videos (they don't play in the app either)
VIDEO_FIXES = {
    "numbers_fixed/first.mp4": "numbers_fixed/1_first.mp4",
    "numbers_fixed/second.mp4": "numbers_fixed/2_second.mp4",
    "numbers_fixed/third.mp4": "numbers_fixed/3_third.mp4",
}


def uz(text: str) -> str:
    """Uzbek letters oʻ / gʻ with the proper sign, like the dashboard."""
    text = re.sub(r"([OoGg])['’‘`]", r"\1ʻ", text)
    return text.replace("'", "ʼ")


def class_items(name: str) -> list[dict]:
    m = re.search(rf"class {name} \{{(.*?)\n\}}", SOURCE, re.S)
    if not m:
        raise SystemExit(f"class {name} not found in the app")
    items = []
    for video, key in re.findall(r"'video':\s*'([^']*)'.*?'title':\s*loc(?:alizations)?\.translate\('([^']+)'\)", m.group(1), re.S):
        items.append({"video": video, "key": key})
    return items


def word_from(key: str) -> dict[str, str | None]:
    """'Ota' so'zi belgisi / Символ слова «Отец» / ... representing the words "father" -> Ota / Отец / father."""
    uz_title = LANG["uz"].get(key) or ""
    ru_title = LANG["ru"].get(key) or ""
    en_sub = LANG["en"].get(f"{key}_sub") or ""
    en_title = LANG["en"].get(key) or ""

    # Ordinals and number words: the app's texts say e.g. "1-birinchi raqam belgisi"
    if key in NUMBER_WORDS:
        return NUMBER_WORDS[key]
    if key.startswith("number_"):
        number = re.search(r"\d+", en_title) or re.search(r"\d+", uz_title)
        if number:
            return {"uz": number.group(0), "ru": number.group(0), "en": number.group(0)}
        # first / second / third
        return {
            "uz": uz(re.sub(r"\s*(raqam|son)?\s*belgisi$", "", uz_title).strip(" '\"")) or None,
            "ru": (re.search(r"[«\"]([^»\"]+)[»\"]", ru_title) or re.search(r"(\S+)$", ru_title)).group(1) if ru_title else None,
            "en": re.sub(r"(?i)^number\s+|\s+symbol$", "", en_title) or None,
        }

    # "'Ota' so'zi belgisi", "'Ovqat' so'zining belgisi"
    uz_word = re.sub(r"['’‘ʼ]?\s*so['ʻ’‘]z(?:i|ining)\s+belgisi$", "", uz_title).strip(" '\"‘’“”«»")
    ru_word = re.search(r"«([^»]+)»", ru_title)
    en_word = re.search(r"\"([^\"]+)\"", en_sub)
    return {
        "uz": uz(uz_word) if uz_word else None,
        "ru": ru_word.group(1) if ru_word else None,
        "en": en_word.group(1) if en_word else None,
    }


lessons = []
for key, letters in ALPHABET.items():
    words = []
    for letter in letters:
        file = LETTER_VIDEO.get(letter, f"level_{letter}.mp4")
        words.append({
            "word": letter, "translationRu": None, "translationEn": None, "kind": "letter",
            "video": f"alphabet_fixed/{file}" if (VIDEOS / "alphabet_fixed" / file).exists() else None,
        })
    lessons.append({"key": key, "course": "alphabet", "place": int(key.split("_")[1]), "words": words})

missing = []
for key, classes in LESSON_CLASSES.items():
    prefix, _, place = key.partition("_")
    words = []
    for cls in classes:
        for item in class_items(cls):
            w = word_from(item["key"])
            if not w["uz"]:
                missing.append(item["key"])
                continue
            video = item["video"].removeprefix("assets/videos/") if item["video"] else None
            video = VIDEO_FIXES.get(video, video) if video else None
            if video and not (VIDEOS / video).exists():
                video = None
            words.append({
                "word": w["uz"], "translationRu": w["ru"], "translationEn": w["en"],
                "kind": KIND.get(prefix, "word"), "video": video,
            })
    if words:
        lessons.append({"key": key, "course": COURSE[prefix], "place": int(place), "words": words})

OUT.write_text(json.dumps({"lessons": lessons}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
total = sum(len(lesson["words"]) for lesson in lessons)
with_video = sum(1 for lesson in lessons for w in lesson["words"] if w["video"])
print(f"{len(lessons)} lessons, {total} words ({with_video} with a video) -> {OUT}")
if missing:
    print(f"skipped {len(missing)} words without an Uzbek name: {missing}")

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/l10n/app_localizations.dart';

void main() {
  final json = {
    'id': 1, 'title': 'A – E', 'titleRu': 'А – Е', 'titleEn': '',
    'exercises': [
      {
        'id': 7, 'type': 'chooseText', 'prompt': 'Bu nima?', 'promptRu': 'Что это?', 'promptEn': 'What is it?',
        'options': [
          {'id': 1, 'text': 'olma', 'textRu': 'яблоко', 'textEn': null},
          {'id': 2, 'text': 'nok', 'textRu': '  ', 'textEn': 'pear'},
        ],
      },
    ],
  };

  test('lesson texts come in the app language', () {
    final ru = ApiLessonDetail.fromJson(json, lang: 'ru');
    expect(ru.title, 'А – Е');
    expect(ru.exercises.first.prompt, 'Что это?');
    expect(ru.exercises.first.options.map((o) => o.text), ['яблоко', 'nok']);

    final en = ApiLessonDetail.fromJson(json, lang: 'en');
    expect(en.title, 'A – E'); // empty translation -> Uzbek
    expect(en.exercises.first.prompt, 'What is it?');
    expect(en.exercises.first.options.map((o) => o.text), ['olma', 'pear']);

    final uz = ApiLessonDetail.fromJson(json, lang: 'uz');
    expect(uz.exercises.first.prompt, 'Bu nima?');
  });

  test('sign details and lesson cards fall back to Uzbek', () {
    final sign = ApiSignDetail.fromJson({
      'id': 3, 'word': 'salom', 'translationRu': 'привет', 'kind': 'word',
      'meaning': 'Salomlashish', 'meaningEn': 'A greeting', 'handShape': 'Ochiq kaft',
    }, lang: 'en');
    expect(sign.meaning, 'A greeting');
    expect(sign.handShape, 'Ochiq kaft');
    expect(sign.wordFor('en'), 'salom');
    expect(sign.wordFor('ru'), 'привет');

    final lesson = ApiLesson.fromJson({'id': 1, 'title': 'Oila', 'titleRu': 'Семья', 'description': 'Tavsif'});
    expect(lesson.titleFor('ru'), 'Семья');
    expect(lesson.titleFor('en'), 'Oila');
    expect(lesson.descriptionFor('ru'), 'Tavsif');
  });

  test('dictionary rows find the syllables in the "Phrases" of the language file', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final en = AppLocalizations(const Locale('en'));
    await en.load();
    expect(en.phrasesFor('uncle'), 'un-cle');
    expect(en.phrasesFor(' Divorce '), 'di-vorce');
    expect(en.phrasesFor('no such word'), isNull);

    final ru = AppLocalizations(const Locale('ru'));
    await ru.load();
    expect(ru.phrasesFor('Брат'), 'брат'); // title is "Брат (старший / младший)"
    expect(ru.phrasesFor('Ребенок'), 'ре-бё-нок'); // ё / е

    final uz = AppLocalizations(const Locale('uz'));
    await uz.load();
    expect(uz.phrasesFor('Aka/Uka'), 'a-ka / u-ka');
  });
}

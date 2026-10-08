import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiDictionary/server/apiSignList.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_lesson_intro.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_textbooks.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/screens/textbooks.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'), (call) async => ['wifi'],
    );
  });

  Future<void> show(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2316);
    tester.view.devicePixelRatio = 2.8125;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('uz'),
        supportedLocales: const [Locale('en'), Locale('uz'), Locale('ru')],
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: home,
      ));
      await Future.delayed(const Duration(milliseconds: 600));
    });
    await tester.pump();
  }

  final lesson = ApiLesson(id: 1, title: '1-10 raqamlari', description: 'Murakkabroq sonlarni imo-ishora orqali oʻrganing.', durationMinutes: 5, exerciseCount: 10, signCount: 10, difficulty: 'easy');

  testWidgets('About lesson screen', (t) => show(t, ApiLessonIntro(lesson: lesson)));
  testWidgets('lesson cards with every status', (t) => show(t, Scaffold(body: ListView(padding: const EdgeInsets.all(20), children: [
    for (final status in LessonStatus.values) ApiLessonCard(lesson: lesson, status: status),
  ]))));
  testWidgets('dictionary sign rows', (t) => show(t, Scaffold(body: ListView(padding: const EdgeInsets.all(16), children: [
    ApiSignTile(sign: ApiSign(id: 1, word: 'Oila', transcription: 'oi-la', translationRu: 'Семья', translationEn: 'Family', kind: 'word')),
    ApiSignTile(sign: ApiSign(id: 2, word: 'Juda uzun soʻz birikmasi namunasi', kind: 'phrase')),
  ]))));
}

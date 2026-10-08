import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/choose_image_exercise.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/choose_text_exercise.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/lesson_parts.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/matching_exercise.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/order_exercise.dart';
import 'package:signlang/l10n/app_localizations.dart';

ApiExercise _exercise(String type, List<String> words, {bool videos = false}) => ApiExercise(
  id: 1, type: type, prompt: 'Bu qaysi harf?', signVideo: null,
  options: [for (int i = 0; i < words.length; i++) ApiOption(id: 10 + i, text: words[i], signVideo: videos ? 'http://localhost:8000/media/signs/app/alphabet_fixed/level_A.mp4' : null)],
);

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'), (call) async => ['wifi'],
    );
  });

  Future<void> show(WidgetTester tester, Widget Function(AnswerResult? result) build, AnswerResult result) async {
    tester.view.physicalSize = const Size(1080, 2316);
    tester.view.devicePixelRatio = 2.8125;
    addTearDown(tester.view.reset);
    Widget app(AnswerResult? r) => MaterialApp(
      locale: const Locale('uz'),
      supportedLocales: const [Locale('en'), Locale('uz'), Locale('ru')],
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        build(r),
        if (r != null) LessonFeedbackBanner(isCorrect: r.isCorrect, correctAnswer: 'A'),
        LessonCheckButton(checked: r != null, isCorrect: r?.isCorrect, canCheck: true, busy: false, last: false, onCheck: () {}, onNext: () {}),
      ]))),
    );
    await tester.runAsync(() async { await tester.pumpWidget(app(null)); await Future.delayed(const Duration(milliseconds: 600)); });
    await tester.pump();
    // before checking: tap the first answer
    for (final word in ['A', 'Salom']) {
      final f = find.text(word);
      if (f.evaluate().isNotEmpty) { await tester.tap(f.first, warnIfMissed: false); await tester.pump(); break; }
    }
    // after checking
    await tester.pumpWidget(app(result));
    await tester.pump();
  }

  final words = ['A', 'B', 'D', 'E'];

  testWidgets('chooseText template', (t) => show(t, (r) => ChooseTextExercise(exercise: _exercise('chooseText', words), result: r, question: 'Bu qaysi harf?', onAnswer: (_) {}), AnswerResult(isCorrect: false, correctOptionId: 10)));
  testWidgets('chooseImage template', (t) => show(t, (r) => ChooseImageExercise(exercise: _exercise('chooseImage', words), result: r, question: '4 qayerda?', onAnswer: (_) {}), AnswerResult(isCorrect: true, correctOptionId: 10)));
  testWidgets('order template', (t) => show(t, (r) => OrderExercise(exercise: _exercise('order', ['Salom', 'mening', 'ismim', 'Ahmad']), result: r, question: 'Gapni tuzing', onAnswer: (_) {}), AnswerResult(isCorrect: false, correctOrder: [10, 11, 12, 13])));
  testWidgets('matching template', (t) => show(t, (r) => MatchingExercise(exercise: _exercise('matching', words, videos: true), result: r, question: 'Juftlang', onAnswer: (_) {}), AnswerResult(isCorrect: true)));
}

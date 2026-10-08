import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/components/uiTranslation/group/translator.dart';
import 'package:signlang/screens/translation.dart';

void main() {
  // pages wait for the internet check (AppLoading): answer "wifi" since tests have no connectivity plugin
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'), (call) async => ['wifi'],
    );
  });

  Future<void> pumpTab(WidgetTester tester, {required bool unlocked, String lang = 'uz', Widget home = const Translator()}) async {
    SharedPreferences.setMockInitialValues({if (unlocked) 'lp_completed': ['alp_0']});
    await LessonProgress.instance.init();
    tester.view.physicalSize = const Size(1080, 2316);
    tester.view.devicePixelRatio = 2.8125;
    addTearDown(tester.view.reset);
    // the app's texts are read from lang/*.json with real file IO: let it finish
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        supportedLocales: const [Locale('en'), Locale('uz'), Locale('ru')],
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: home,
      ));
      await Future.delayed(const Duration(milliseconds: 900));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('translation tab shows the 4 mode cards', (tester) async {
    await pumpTab(tester, unlocked: true, lang: 'en', home: const Translation());
    // the card list shows a short loading skeleton first (AppLoading): let it finish
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 600)));
    await tester.pump(const Duration(seconds: 1));
    for (final title in ['Gesture → Text', 'Text → Gesture', 'Speech → Text', 'Text → Speech']) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('translator builds (unlocked)', (tester) async {
    await pumpTab(tester, unlocked: true);
    expect(find.byType(Translator), findsOneWidget);
  });

  testWidgets('translator builds (locked)', (tester) async {
    await pumpTab(tester, unlocked: false);
    expect(find.byType(Translator), findsOneWidget);
  });

  testWidgets('every direction from the mode pill, then text → result', (tester) async {
    await pumpTab(tester, unlocked: true, lang: 'en');
    final pairs = ['Voice → Text', 'Voice → Sign', 'Text → Voice', 'Text → Sign', 'Sign → Voice', 'Sign → Text', 'Text → Sign'];
    for (final pair in pairs) {
      // the pill shows the current pair; open it and pick the next one
      await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton && w.child is Container && ((w.child as Container).decoration as BoxDecoration?)?.color != null).last);
      await tester.pump(const Duration(milliseconds: 400)); await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text(pair).last);
      await tester.pump(const Duration(milliseconds: 400)); await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.enterText(find.byType(TextField), 'Salom rahmat 345');
    await tester.pump();
    await tester.tap(find.text('Show result'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byIcon(Icons.sync_alt_rounded));
    await tester.pump(const Duration(milliseconds: 400)); await tester.pump(const Duration(milliseconds: 400));
  });
}

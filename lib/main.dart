import 'package:flutter/material.dart';
import 'package:signlang/api/api_service.dart';
import 'package:signlang/services/notification_center.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/components/splashScreenUI.dart';
import 'package:signlang/customBottomNav.dart';
import 'package:signlang/screens/dictionary.dart';
import 'package:signlang/screens/profile.dart';

import 'package:signlang/screens/textbooks.dart';
import 'package:signlang/screens/translation.dart';

import 'components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'components/web/connectivity/connectivityGate.dart';
import 'l10n/app_localizations.dart';
import 'components/log/langguageChoose.dart';

import 'package:signlang/services/statistics_service.dart';
import 'package:signlang/services/app_sheets.dart';
import 'package:signlang/services/theme_service.dart';
import 'package:signlang/services/push_service.dart';
import 'package:signlang/services/firebase_setup.dart';
import 'package:signlang/services/lesson_sync.dart';
import 'package:signlang/services/onboarding_answers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LessonProgress.instance.init();
  await StatisticsService.instance.init();
  await ThemeService.instance.init();
  // Firebase: email sign-in and push notifications (off if the Firebase config is missing)
  await FirebaseSetup.init();
  await PushService.init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final prefs = await SharedPreferences.getInstance();
  final int initialTab = prefs.getInt('tabIndex') ?? 0;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String lang = prefs.getString('lang') ?? 'en';
  runApp(MyApp(
    initialTab: initialTab,
    isLoggedIn: isLoggedIn,
    lang: lang
  ));
}

class MyApp extends StatefulWidget {
  final int initialTab;
  final bool isLoggedIn;
  final String lang;

  const MyApp({
    super.key,
    required this.initialTab,
    required this.isLoggedIn,
    required this.lang
  });

  static _MyAppState of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Locale _locale = Locale(widget.lang);

  /// Back within this time → the app is exactly where it was; longer → it starts fresh from the splash.
  static const Duration _keepStateFor = Duration(minutes: 20);
  DateTime? _leftAt;

  void setLocale(Locale newLocale) async {
    setState(() { _locale = newLocale; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', newLocale.languageCode); // main() reads 'lang' on startup
  }

  @override
  void initState() {
    super.initState();
    ThemeService.instance.mode.addListener(_onThemeChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ThemeService.instance.mode.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      _leftAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final leftAt = _leftAt;
      _leftAt = null;
      // the Android screen may have been recreated while away: restore the system bars setting
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (leftAt != null && DateTime.now().difference(leftAt) >= _keepStateFor) _startFresh();
    }
  }

  // same start as a cold launch: splash, then the saved tab / login flow
  Future<void> _startFresh() async {
    final prefs = await SharedPreferences.getInstance();
    AppSheets.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => SplashController(initialTab: prefs.getInt('tabIndex') ?? 0, isLoggedIn: prefs.getBool('isLoggedIn') ?? false)),
      (route) => false,
    );
  }

  // Many widgets read colors through AppPalette (not Theme.of), so they don't
  // rebuild on their own when the mode flips — mark the whole tree dirty.
  void _onThemeChanged() {
    setState(() {});
    void rebuild(Element el) { el.markNeedsBuild(); el.visitChildren(rebuild); }
    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ThemeService.instance.isDark;
    return MaterialApp(
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('uz', ''),
        Locale('ru', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) { if (supportedLocale.languageCode == locale?.languageCode) { return supportedLocale; } }
        return supportedLocales.first;
      },
      navigatorKey: AppSheets.navigatorKey,
      navigatorObservers: [AppSheets.observer],
      debugShowCheckedModeBanner: false,
      title: 'UZSL',
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: ThemeService.instance.mode.value,
      // AppPalette colors switch instantly, so the theme must too.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: ConnectivityGate(child: child!),
      ),
      home: SplashController(initialTab: widget.initialTab, isLoggedIn: widget.isLoggedIn),
    );
  }
}

// --- SPLASH CONTROLLER ---

class SplashController extends StatefulWidget {
  final int initialTab;
  final bool isLoggedIn;

  const SplashController({
    super.key,
    required this.initialTab,
    required this.isLoggedIn,
  });

  @override
  State<SplashController> createState() => _SplashControllerState();
}

class _SplashControllerState extends State<SplashController> {
  @override
  void initState() { super.initState(); _handleNavigation(); }

  void _handleNavigation() async {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Keep splash screen visible for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // A required update blocks the app behind a non-dismissible sheet.
    if (await AppSheets.checkForUpdate()) return;
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainWrapper(initialTab: 0)), (route) => false);
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LanguageChoose()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) { return const SplashScreenUI(); }
}

// --- MAIN APPLICATION WRAPPER (Authenticated Flow) ---
class MainWrapper extends StatefulWidget {
  final int initialTab;
  const MainWrapper({super.key, required this.initialTab});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  bool _focusDictionarySearch = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _setLoggedIn();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Open a notification tapped while the app was starting
      PushService.mainScreenReady();
    });
    // The server learns where to send this user's pushes (also refreshes an old token)
    PushService.registerDevice();
    // Lesson results finished while offline
    LessonSync.flush();
    // Onboarding answers not sent yet (e.g. Google/Apple login, or offline at login)
    OnboardingAnswers.sync();
    // Keeps the bell's PulseDot up to date, and rings for new notifications
    NotificationCenter.start();
    // The daily goal picked in onboarding (before login) goes to the server
    StatisticsService.instance.syncDailyGoal();
    // A name/photo saved while the server couldn't be reached
    ApiService.syncPending();
  }

  @override
  void dispose() { PushService.mainScreenGone(); super.dispose(); }

  Future<void> _setLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  Widget getActiveTab(int index) {
    switch (index) {
      case 0: return Textbooks(onOpenDictionary: _openDictionarySearch);
      case 1: return Dictionary(autoFocusSearch: _focusDictionarySearch, onSearchFocused: () => _focusDictionarySearch = false);
      case 2: return Translation();
      case 3: return const Profile();
      default: return const Textbooks();
    }
  }

  void _updateTabSelection(int index) async {
    setState(() { _currentIndex = index; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tabIndex', index);
  }

  void _openDictionarySearch() { setState(() { _currentIndex = 1; _focusDictionarySearch = true; }); }

  @override
  Widget build(BuildContext context){
    final String textbooks = AppLocalizations.of(context)!.translate('textbooks');
    final String dictionary = AppLocalizations.of(context)!.translate('dictionary');
    final String translation = AppLocalizations.of(context)!.translate('translation');
    final String profile = AppLocalizations.of(context)!.translate('profile');

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Textbooks(onOpenDictionary: _openDictionarySearch),
          Dictionary(autoFocusSearch: _focusDictionarySearch, onSearchFocused: () => _focusDictionarySearch = false ),
          Translation(isActive: _currentIndex == 2), // stops camera / mic / video when another tab is shown
          const Profile(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _updateTabSelection,
        items: [
          NavItem(icon: Icons.menu_book_rounded, label: textbooks),
          NavItem(icon: Icons.search_rounded, label: dictionary),
          NavItem(icon: Icons.translate_rounded, label: translation),
          NavItem(icon: Icons.person_rounded, label: profile),
        ],
      ),
    );
  }
}


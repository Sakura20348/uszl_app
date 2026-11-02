import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_lesson_intro.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/buildLessonsTextbooks.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/screens/textbooks.dart';
import 'package:signlang/services/theme_service.dart';

/// Textbooks the app always shows and opens with its own screens (their lessons and exercises still come
/// from the dashboard when it has them). App card id → dashboard slug.
const Map<String, String> appTextbookSlugs = {'0': 'alphabet', '1': 'numbers', '2': 'introduction'};

/// The dashboard's built-in textbook pictures ("/textbooks/food.webp"), bundled in assets/textbooks/
const Set<String> _bundledIcons = {
  'alphabet', 'daily-life', 'family', 'feelings', 'food', 'medicine', 'numbers', 'public-services', 'sports', 'transportation',
};
String? bundledIcon(String? icon) {
  final name = RegExp(r'^/textbooks/([\w-]+)\.webp$').firstMatch(icon ?? '')?.group(1);
  return _bundledIcons.contains(name) ? 'assets/textbooks/$name.webp' : null;
}

/// Server textbook slug → id prefix of the app's own lesson screens ("alp_0" = first Alphabet lesson)
const Map<String, String> _builtInLessonPrefixes = {'alphabet': 'alp', 'numbers': 'num', 'family': 'fam', 'food': 'eat', 'feelings': 'feel'};

/// The textbooks the dashboard publishes: the app shows exactly these, in the dashboard's order.
class ServerTextbooks {
  ServerTextbooks._();
  static Future<List<ApiCourse>>? _request;
  static const String _prefsKey = 'published_textbooks';

  /// Null = never loaded (offline on the very first start): the app's own cards are shown.
  /// Kept on the phone for offline starts.
  static final ValueNotifier<List<ApiCourse>?> courses = ValueNotifier(null);

  /// Pictures set in the dashboard for the app's own lessons: lesson id ("alp_0") → url.
  static final ValueNotifier<Map<String, String>> lessonImages = ValueNotifier({});

  /// Loads the textbooks saved last time, then asks the server for fresh ones.
  static Future<void> sync() async {
    if (courses.value == null) {
      try {
        final saved = (await SharedPreferences.getInstance()).getString(_prefsKey);
        if (saved != null && courses.value == null) { courses.value = (jsonDecode(saved) as List).map((e) => ApiCourse.fromJson(e as Map<String, dynamic>)).toList(); }
      } catch (_) {}
    }
    try { await all(refresh: true); } catch (_) {}
  }

  static Future<List<ApiCourse>> all({bool refresh = false}) {
    if (refresh || _request == null) {
      final request = UzslApi.courses();
      _request = request;
      request.then((list) async { courses.value = list; (await SharedPreferences.getInstance()).setString(_prefsKey, jsonEncode([for (final c in list) c.toJson()])); }).catchError((Object _) { _request = null; });
    }
    return _request!;
  }

  /// One card per dashboard textbook, in the dashboard's order, with its title and picture.
  /// The app's own textbooks ([appCards]: Alphabet, Numbers, Introduction) keep their screens and progress,
  /// and their picture until one is uploaded in the dashboard; one the dashboard doesn't have is still
  /// shown, last.
  static List<Map<String, dynamic>> cards(List<Map<String, dynamic>> appCards, String lang) {
    final list = courses.value ?? const <ApiCourse>[];
    final slugs = list.map((c) => c.slug).toSet();
    Map<String, dynamic>? appCardOf(String slug) => appCards.where((a) => appTextbookSlugs[a['id']] == slug).firstOrNull;
    String? uploaded(ApiCourse course) => (course.icon?.startsWith('/media/') ?? false) ? UzslApi.mediaUrl(course.icon) : null;
    return [
      for (final course in list)
        if (appCardOf(course.slug) case final app?)
          {
            ...app, 'titleKey': course.titleFor(lang), 'image': ?bundledIcon(course.icon), 'imageUrl': ?uploaded(course),
            if (course.lessonCount > 0) ...{
              'subKey': 'lessons', 'letter': 'completed_lessons',
              'learned': course.completedLessons, 'total': course.lessonCount, 'serverProgress': true,
            },
          }
        else
          {
            'id': 'api_${course.id}', 'image': bundledIcon(course.icon) ?? 'web/images/book_3d.webp', 'imageWidth': 115.0, 'imageUrl': ?uploaded(course),
            'titleKey': course.titleFor(lang), 'subKey': 'lessons', 'letter': 'completed_lessons',
            'learned': course.completedLessons, 'total': course.lessonCount, 'count': course.total ?? course.lessonCount, 'course': course,
          },
      ...appCards.where((a) => !slugs.contains(appTextbookSlugs[a['id']])),
    ];
  }

  /// Status of card [i]: every card, the app's and the dashboard's, opens when the one before it is
  /// finished. A dashboard textbook (or an app card counting the dashboard's lessons) is finished when all
  /// its lessons are done; one with no lessons yet doesn't block the cards after it. [appPassed] says
  /// whether app card k is finished.
  static LessonStatus statusAt(List<Map<String, dynamic>> items, int i, bool Function(int k) appPassed) {
    bool empty(int k) => (items[k]['course'] as ApiCourse?)?.lessonCount == 0;
    bool done(int k) {
      final course = items[k]['course'] as ApiCourse?;
      if (items[k]['serverProgress'] == true) return (items[k]['learned'] as int) >= (items[k]['total'] as int);
      if (course == null) return appPassed(k);
      if (course.lessonCount == 0) return k == 0 || done(k - 1);
      return course.completedLessons >= course.lessonCount;
    }
    if (!empty(i) && done(i)) return LessonStatus.passed;
    if (i == 0 || done(i - 1)) return LessonStatus.opened;
    return LessonStatus.locked;
  }

  static Future<ApiCourse?> bySlug(String slug, {bool refresh = false}) async { try { return (await all(refresh: refresh)).where((c) => c.slug == slug).firstOrNull; } on ApiException { return null; } }
}

/// Opens the lessons of a dashboard textbook card. Returns false for the app's own cards (offline before
/// the first load), which open their own screens.
Future<bool> openTextbookCard(BuildContext context, Map<String, dynamic> card) async {
  final course = card['course'] as ApiCourse?;
  if (course == null) return false;
  if (course.lessonCount == 0) { showGreySnackBar(context, AppLocalizations.of(context)!.translate('textbook_no_lessons')); return true; }
  await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiCourseScreen(course: course, image: card['image'] as String? ?? 'web/images/book_3d.webp')));
  await ServerTextbooks.sync();
  return true;
}

/// The lessons of a dashboard textbook (same look as the app's own textbook pages).
class ApiCourseScreen extends StatefulWidget {
  final ApiCourse course;
  /// Picture for lessons that have none
  final String image;
  const ApiCourseScreen({super.key, required this.course, this.image = 'web/images/book_3d.webp'});

  @override
  State<ApiCourseScreen> createState() => _ApiCourseScreenState();
}

class _ApiCourseScreenState extends State<ApiCourseScreen> {
  List<ApiLesson>? _lessons;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final lessons = await UzslApi.courseLessons(widget.course.id);
      // Done lessons are kept on the phone too: Translation unlocks after the first one, and the app's
      // own lesson screens (used offline) show the same progress
      final prefix = _builtInLessonPrefixes[widget.course.slug];
      LessonProgress.instance.restoreCompleted([
        for (var i = 0; i < lessons.length; i++)
          if (lessons[i].status == 'completed') ...['api_${lessons[i].id}', if (prefix != null) '${prefix}_$i'],
      ]);
      if (mounted) setState(() => _lessons = lessons);
    } on ApiException catch (e) { if (mounted) { setState(() => _lessons ??= []); showApiError(context, e, onRetry: _load); } }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final lessons = _lessons;
    final int done = lessons?.where((l) => l.status == 'completed').length ?? widget.course.completedLessons;
    final int total = lessons?.length ?? widget.course.lessonCount;
    final double progress = total == 0 ? 0 : done / total;
    final String subtitle = (widget.course.subtitle?.trim().isNotEmpty ?? false)
      ? widget.course.subtitle!
      : ((widget.course.descriptionFor(lang)?.trim().isNotEmpty ?? false) ? widget.course.descriptionFor(lang)! : '$total ${loc.translate('lessons').toLowerCase()}');

    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== 1) back =====
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.arrow_back_outlined)),
                        ),
                        // ===== 2) title =====
                        const SizedBox(height: 16), Text(widget.course.titleFor(lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                        Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[600]!))), const SizedBox(height: 16),
                        // ===== 3) progress =====
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
                            boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
                          ),
                          child: Column(children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text('$done/$total ${loc.translate('completed_lessons').toLowerCase()}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
                                Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppPalette.fg(Colors.blue[900]!))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: AppPalette.bg(const Color(0xFF42A5F5)).withValues(alpha: 0.3), valueColor: AlwaysStoppedAnimation(AppPalette.fg(const Color(0xFF4A7FE0))))
                            )
                          ])
                        )
                      ]
                    )
                  )
                ),
                // ===== 4) lessons =====
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.translate('lessons'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                        const SizedBox(height: 16),
                        if (lessons == null)
                          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                        else
                          for (var i = 0; i < lessons.length; i++)
                            ApiLessonCard(lesson: lessons[i], status: apiLessonStatus(lessons, i), image: widget.image, onDone: _load)
                      ]
                    )
                  )
                )
              ]
            )
          )
        )
      )
    );
  }
}

/// Lessons open one after another, like the app's own: done = passed, the next one = opened, later ones = locked.
LessonStatus apiLessonStatus(List<ApiLesson> lessons, int i) {
  if (lessons[i].status == 'completed') return LessonStatus.passed;
  if (i == 0 || lessons[i - 1].status == 'completed') return LessonStatus.opened;
  return LessonStatus.locked;
}

/// One server lesson as the app's lesson card (picture, status badge, minutes · signs); opens "About lesson".
class ApiLessonCard extends StatelessWidget {
  final ApiLesson lesson;
  final LessonStatus status;
  final String image;
  final VoidCallback? onDone;
  const ApiLessonCard({super.key, required this.lesson, required this.status, this.image = 'web/images/book_3d.webp', this.onDone});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final int signs = lesson.signCount > 0 ? lesson.signCount : lesson.exerciseCount;
    return GestureDetector(
      onTap: status == LessonStatus.locked ? null : () async { if (await openApiLesson(context, lesson, image: image)) onDone?.call(); },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: BuildAllLessons.buildAllLessons(context, {
          'image': image, 'imageUrl': ?lesson.thumbnail,
          'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp',
          'titleKey': lesson.titleFor(Localizations.localeOf(context).languageCode),
          'time': '${lesson.durationMinutes} ${loc.translate('time_min')}',
          'click': '$signs ${loc.translate('hints')}',
          'status': status
        })
      )
    );
  }
}

/// "About lesson", then the lesson; false when it has no exercises yet (a message is shown).
Future<bool> openApiLesson(BuildContext context, ApiLesson lesson, {String image = 'web/images/book_3d.webp'}) async {
  if (lesson.exerciseCount == 0) { showRedSnackBar(context, AppLocalizations.of(context)!.translate('lesson_no_exercises')); return false; }
  await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiLessonIntro(lesson: lesson, fallbackImage: image)));
  return true;
}

/// Lessons added in the dashboard to one of the app's own textbooks: the server's lessons after the
/// [builtInCount] the app has screens for. Shows nothing while loading, offline, or when there are none.
class ApiExtraLessons extends StatefulWidget {
  final String slug;
  final int builtInCount;
  final String image;
  const ApiExtraLessons({super.key, required this.slug, required this.builtInCount, this.image = 'web/images/book_3d.webp'});

  @override
  State<ApiExtraLessons> createState() => _ApiExtraLessonsState();
}

class _ApiExtraLessonsState extends State<ApiExtraLessons> {
  List<ApiLesson> _all = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final course = await ServerTextbooks.bySlug(widget.slug, refresh: true);
    if (course == null || course.lessonCount == 0) return;
    try {
      final lessons = await UzslApi.courseLessons(course.id);
      final prefix = _builtInLessonPrefixes[widget.slug];
      if (prefix != null) {
        ServerTextbooks.lessonImages.value = {
          for (final e in ServerTextbooks.lessonImages.value.entries) if (!e.key.startsWith('${prefix}_')) e.key: e.value,
          for (var i = 0; i < lessons.length; i++) if (lessons[i].thumbnail != null) '${prefix}_$i': lessons[i].thumbnail!,
        };
      }
      if (mounted) setState(() => _all = lessons);
    } on ApiException catch (e) { debugPrint('Extra lessons of ${widget.slug} not loaded: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = widget.builtInCount; i < _all.length; i++)
          ApiLessonCard(lesson: _all[i], status: apiLessonStatus(_all, i), image: widget.image, onDone: _load)
      ]
    );
  }
}

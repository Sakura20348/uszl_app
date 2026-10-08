import 'package:flutter/material.dart';

import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_lesson_intro.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/buildLessonsTextbooks.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/screens/textbooks.dart';
import 'package:signlang/services/theme_service.dart';

/// The app's own textbook cards (LessonsTextbooksData id → server slug). They are not listed a second time
/// here; cards without their own screens open the server textbook instead (see openServerTextbook).
const Map<String, String> builtInTextbookSlugs = {
  '0': 'alphabet', '1': 'numbers', '2': 'family', '3': 'food', '4': 'feelings',
  '5': 'daily-life', '6': 'medicine', '7': 'transportation', '8': 'public-services', '9': 'sports',
};

/// Server textbooks by slug, fetched once and refreshed when asked.
class ServerTextbooks {
  ServerTextbooks._();
  static Future<List<ApiCourse>>? _courses;

  static Future<List<ApiCourse>> all({bool refresh = false}) {
    if (refresh || _courses == null) {
      _courses = UzslApi.courses();
      _courses!.catchError((Object _) { _courses = null; return <ApiCourse>[]; });
    }
    return _courses!;
  }

  static Future<ApiCourse?> bySlug(String slug, {bool refresh = false}) async {
    try {
      return (await all(refresh: refresh)).where((c) => c.slug == slug).firstOrNull;
    } on ApiException {
      return null;
    }
  }
}

/// A built-in textbook card the app has no screens for: opens its lessons from the server.
/// Returns false when the server has no lessons for it (yet) or can't be reached.
Future<bool> openServerTextbook(BuildContext context, String slug) async {
  final course = await ServerTextbooks.bySlug(slug, refresh: true);
  if (course == null || course.lessonCount == 0 || !context.mounted) return false;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiCourseScreen(course: course)));
  return true;
}

/// Textbooks made and published in the dashboard, shown after the app's own textbooks.
/// Shows nothing while loading, when offline, or when there are none.
class ApiTextbookList extends StatefulWidget {
  const ApiTextbookList({super.key});

  @override
  State<ApiTextbookList> createState() => _ApiTextbookListState();
}

class _ApiTextbookListState extends State<ApiTextbookList> {
  List<ApiCourse> _courses = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final all = await UzslApi.courses();
      final courses = all.where((c) => !builtInTextbookSlugs.containsValue(c.slug) && c.lessonCount > 0).toList();
      if (mounted) setState(() => _courses = courses);
    } on ApiException catch (e) {
      debugPrint('Dashboard textbooks not loaded: $e');
    }
  }

  Future<void> _open(ApiCourse course) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiCourseScreen(course: course)));
    _load(); // progress may have changed
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        for (final course in _courses)
          GestureDetector(
            onTap: () => _open(course),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: BuildLessonsTextbooks.buildLessonTextbooks(context, {
                'id': 'api_${course.id}',
                'image': 'web/images/book_3d.png',
                if (course.icon?.startsWith('/media/') ?? false) 'imageUrl': UzslApi.mediaUrl(course.icon),
                'imageWidth': 115.0,
                'titleKey': course.titleFor(lang),
                'subKey': 'lessons',
                'letter': 'completed_lessons',
                'learned': course.completedLessons,
                'total': course.lessonCount,
                'status': course.completedLessons >= course.lessonCount ? LessonStatus.passed : LessonStatus.opened,
              }),
            ),
          ),
      ],
    );
  }
}

/// The lessons of a dashboard textbook (same look as the app's own textbook pages).
class ApiCourseScreen extends StatefulWidget {
  final ApiCourse course;
  /// Picture for lessons that have none
  final String image;
  const ApiCourseScreen({super.key, required this.course, this.image = 'web/images/book_3d.png'});

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
      if (mounted) setState(() => _lessons = lessons);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _lessons ??= []);
        showApiError(context, e, onRetry: _load);
      }
    }
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
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
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
                        const SizedBox(height: 16),
                        // ===== 2) title =====
                        Text(widget.course.titleFor(lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                        Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[600]!))),
                        const SizedBox(height: 16),
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
                              child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: AppPalette.bg(const Color(0xFF42A5F5)).withValues(alpha: 0.3), valueColor: AlwaysStoppedAnimation(AppPalette.fg(const Color(0xFF4A7FE0)))),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
                // ===== 4) lessons =====
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.translate('lessons'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                        const SizedBox(height: 16),
                        if (lessons == null)
                          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                        else
                          for (var i = 0; i < lessons.length; i++)
                            ApiLessonCard(lesson: lessons[i], status: apiLessonStatus(lessons, i), image: widget.image, onDone: _load),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  const ApiLessonCard({super.key, required this.lesson, required this.status, this.image = 'web/images/book_3d.png', this.onDone});

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
          'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png',
          'titleKey': lesson.titleFor(Localizations.localeOf(context).languageCode),
          'time': '${lesson.durationMinutes} ${loc.translate('time_min')}',
          'click': '$signs ${loc.translate('hints')}',
          'status': status,
        }),
      ),
    );
  }
}

/// "About lesson", then the lesson; false when it has no exercises yet (a message is shown).
Future<bool> openApiLesson(BuildContext context, ApiLesson lesson, {String image = 'web/images/book_3d.png'}) async {
  if (lesson.exerciseCount == 0) {
    showRedSnackBar(context, AppLocalizations.of(context)!.translate('lesson_no_exercises'));
    return false;
  }
  await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiLessonIntro(lesson: lesson, fallbackImage: image)));
  return true;
}

/// Lessons added in the dashboard to one of the app's own textbooks: the server's lessons after the
/// [builtInCount] the app has screens for. Shows nothing while loading, offline, or when there are none.
class ApiExtraLessons extends StatefulWidget {
  final String slug;
  final int builtInCount;
  final String image;
  const ApiExtraLessons({super.key, required this.slug, required this.builtInCount, this.image = 'web/images/book_3d.png'});

  @override
  State<ApiExtraLessons> createState() => _ApiExtraLessonsState();
}

class _ApiExtraLessonsState extends State<ApiExtraLessons> {
  List<ApiLesson> _all = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final course = await ServerTextbooks.bySlug(widget.slug, refresh: true);
    if (course == null || course.lessonCount <= widget.builtInCount) return;
    try {
      final lessons = await UzslApi.courseLessons(course.id);
      if (mounted) setState(() => _all = lessons);
    } on ApiException catch (e) {
      debugPrint('Extra lessons of ${widget.slug} not loaded: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = widget.builtInCount; i < _all.length; i++)
          ApiLessonCard(lesson: _all[i], status: apiLessonStatus(_all, i), image: widget.image, onDone: _load),
      ],
    );
  }
}

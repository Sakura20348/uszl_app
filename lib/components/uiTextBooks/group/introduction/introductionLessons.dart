import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_textbooks.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'package:signlang/components/uiTextBooks/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:signlang/services/theme_service.dart';

/// The Introduction textbook (card id '2'), same look as the Alphabet one. Its lessons are the
/// dashboard's "introduction" textbook: titles, order and exercises come from there.
class IntroductionLessons extends StatefulWidget {
  const IntroductionLessons({super.key});

  @override
  State<IntroductionLessons> createState() => _IntroductionLessonsState();
}

class _IntroductionLessonsState extends State<IntroductionLessons> {
  static const String _id = '2';
  static const String _slug = 'introduction';
  static const String _image = 'web/images/introduction.webp';

  /// The lessons loaded last time: reopening shows them at once while fresh ones load
  static List<ApiLesson>? _lastLessons;

  bool _isLoading = _lastLessons == null;
  ApiCourse? _course = ServerTextbooks.courses.value?.where((c) => c.slug == _slug).firstOrNull;
  /// Null while loading
  List<ApiLesson>? _lessons = _lastLessons;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (_lessons == null) await AppLoading.ready();
    try {
      // The textbook list is already loaded on the Textbooks screen; only the lessons are fetched
      final course = _course ?? await ServerTextbooks.bySlug(_slug);
      final lessons = course == null ? <ApiLesson>[] : await UzslApi.courseLessons(course.id);
      // Done lessons are kept on the phone too (Translation unlocks after the first one), and the card's
      // "words learned" counts the signs of the done lessons
      LessonProgress.instance.restoreCompleted([for (final l in lessons) if (l.status == 'completed') 'api_${l.id}']);
      LessonProgress.instance.setLearned(_id, lessons.where((l) => l.status == 'completed').fold(0, (sum, l) => sum + l.signCount));
      _lastLessons = lessons;
      if (mounted) setState(() { _course = course; _lessons = lessons; _isLoading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _lessons ??= []; _isLoading = false; });
      showApiError(context, e, onRetry: _load);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final lessons = _lessons ?? const <ApiLesson>[];
    final int done = lessons.where((l) => l.status == 'completed').length;
    final int total = lessons.length;
    final double progress = total == 0 ? 0 : done / total;
    final String title = _course?.titleFor(lang) ?? loc.translate('introduction');
    final String subtitle = _course?.subtitle?.trim().isNotEmpty ?? false
        ? _course!.subtitle!
        : (_course?.descriptionFor(lang)?.trim().isNotEmpty ?? false) ? _course!.descriptionFor(lang)! : '$total ${loc.translate('lessons').toLowerCase()}';

    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load, notificationPredicate: (ScrollNotification notification) { return notification.depth == 0; },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                if (_isLoading)
                  // ======= 1 =======
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(const Color(0xFF42A5F5)).withValues(alpha: 0.2), child: AlphabetLessonsSkeleton.buildSkeleton()))
                else ...[
                  // ======= 2 =======
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== 1) back =====
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.arrow_back_outlined))
                          ),
                          const SizedBox(height: 16),
                          // ===== 2) text =====
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                          Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[600]!))),
                          const SizedBox(height: 16),
                          // ===== 3) how many line =====
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
                              boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Text('$done/$total ${loc.translate('completed_lessons').toLowerCase()}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
                                    Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppPalette.fg(Colors.blue[900]!)))
                                  ]
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: AppPalette.bg(const Color(0xFF42A5F5)).withValues(alpha: 0.3), valueColor: AlwaysStoppedAnimation(AppPalette.fg(const Color(0xFF4A7FE0))))
                                )
                              ]
                            )
                          )
                        ]
                      )
                    )
                  ),
                  // ======= 3 =======
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== 1) text =====
                          Text(loc.translate('lessons'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                          const SizedBox(height: 16),
                          // ===== 2) click to cards: the dashboard's lessons, one after another =====
                          if (lessons.isEmpty)
                            Padding(padding: const EdgeInsets.all(30), child: Center(child: Text(loc.translate('textbook_no_lessons'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppPalette.fg(Colors.grey[600]!)))))
                          else
                            for (var i = 0; i < lessons.length; i++)
                              ApiLessonCard(lesson: lessons[i], status: apiLessonStatus(lessons, i), image: _image, onDone: _load),
                        ]
                      )
                    )
                  )
                ]
              ]
            )
          )
        )
      )
    );
  }
}

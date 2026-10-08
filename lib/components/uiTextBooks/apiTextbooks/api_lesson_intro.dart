import 'package:flutter/material.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_lesson_player.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/theme_service.dart';

/// "About lesson" before a dashboard lesson starts (same look as the app's own lesson start pages):
/// picture, title, description, duration · level · signs, "What will you learn", "Start lesson".
class ApiLessonIntro extends StatelessWidget {
  final ApiLesson lesson;
  /// The textbook's picture, used when the lesson has none
  final String fallbackImage;
  const ApiLessonIntro({super.key, required this.lesson, this.fallbackImage = 'web/images/book_3d.png'});

  Future<void> _start(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiLessonPlayer(lessonId: lesson.id, title: lesson.titleFor(Localizations.localeOf(context).languageCode))));
    // finished or quit: back to the lesson list
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final level = loc.translate(switch (lesson.difficulty) { 'hard' => 'hard', 'medium' => 'medium', _ => 'easy' });
    final lang = Localizations.localeOf(context).languageCode;
    final title = lesson.titleFor(lang);
    final description = lesson.descriptionFor(lang)?.trim() ?? '';
    final thumb = lesson.thumbnail;
    final BoxDecoration glass = BoxDecoration(
      color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
      boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
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
                      const SizedBox(height: 18),
                      // ===== 2) picture =====
                      Container(
                        width: double.infinity, height: 200, decoration: glass, clipBehavior: Clip.antiAlias,
                        child: Center(
                          child: thumb != null
                              ? Image.network(thumb, height: 180, fit: BoxFit.contain, errorBuilder: (_, _, _) => Image.asset(fallbackImage, height: 171))
                              : Image.asset(fallbackImage, height: 171, errorBuilder: (_, _, _) => Icon(Icons.menu_book_rounded, size: 90, color: AppPalette.fg(Colors.blue))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ===== 3) title + description =====
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                      if (description.isNotEmpty)
                        Text(description, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[600]!))),
                      const SizedBox(height: 18),
                      // ===== 4) duration · level · signs =====
                      Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), decoration: glass,
                        child: Row(children: [
                          _stat('web/icons/time.png', loc.translate('duration'), '${lesson.durationMinutes} ${loc.translate('time_min')}'), _divider(),
                          _stat('web/icons/level.png', loc.translate('level'), level), _divider(),
                          _stat('web/icons/hand.png', loc.translate('gesture'), '${lesson.signCount > 0 ? lesson.signCount : lesson.exerciseCount} ${loc.translate('pieces')}'),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      // ===== 5) what you will learn =====
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPalette.bg(const Color(0xFFFFCC80)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(const Color(0xFFFFC107)).withValues(alpha: 0.2)),
                          boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFFFFCC80)).withValues(alpha: 0.9), blurRadius: 15)],
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFFFF176)).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.yellow)), borderRadius: BorderRadius.circular(15)),
                            child: Image.asset('web/icons/info_yellow.png', width: 28, height: 28, color: AppPalette.fg(Colors.orange)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(loc.translate('what_learn'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 4),
                            Text(description.isNotEmpty ? description : loc.translate('what_learn_api').replaceAll('{title}', title), style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14)),
                          ])),
                        ]),
                      ),
                      const Spacer(),
                      const SizedBox(height: 18),
                      // ===== 6) start =====
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: () => _start(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.bg(const Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(const Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                            side: BorderSide(width: 1, color: AppPalette.border(const Color(0xFF1A237E)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: Text(loc.translate('start_lesson'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.blue[900]!))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String imagePath, String label, String value) => Expanded(
    child: Column(children: [
      Image.asset(imagePath, width: 22, height: 22, color: AppPalette.fg(Colors.blue[800]!)), const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.grey[700]!))),
      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _divider() => Container(width: 1, height: 60, color: AppPalette.bg(Colors.grey.shade300));
}

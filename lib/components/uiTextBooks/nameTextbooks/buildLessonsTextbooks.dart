import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../screens/textbooks.dart';
import '../../../services/theme_service.dart';

class BuildLessonsTextbooks {
  static Widget buildLessonTextbooks(BuildContext context, Map<String, dynamic> item) {
    final LessonStatus status = item['status'] as LessonStatus;

    final Color accent = switch (status) {
      LessonStatus.passed => AppPalette.auto(Color(0xFF2E9E4F)),
      LessonStatus.opened => AppPalette.auto(Color(0xFF42A5F5)).withOpacity(0.9),
      LessonStatus.locked => AppPalette.auto(Color(0xFFB0BEC5)),
    };
    
    final Color arrowAccent = switch (status) {
      LessonStatus.passed => AppPalette.auto(Color(0xFF2E9E4F)),
      LessonStatus.opened => AppPalette.auto(Color(0xFF42A5F5)).withOpacity(0.9),
      LessonStatus.locked => AppPalette.auto(Color(0xFFB0BEC5)),
    };

    final IconData iconAccent = switch (status) {
      LessonStatus.passed => Icons.done,
      LessonStatus.opened => Icons.keyboard_arrow_right,
      LessonStatus.locked => Icons.lock,
    };

    final int learned = (item['learned'] ?? 0) as int;
    final int total = (item['total'] ?? 0) as int;
    final double progress = total == 0 ? 0 : learned / total;
    final c = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: c.cardBorder), boxShadow: [BoxShadow(color: accent.withValues(alpha: c.isDark ? 0.3 : 0.9), blurRadius: 15)]
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.translate(item['titleKey']), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.isDark ? c.text : AppPalette.fg(Color(0xFF1A1A2E)))),
                          Container(
                            padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: c.chip, border: Border.all(width: 1, color: c.cardBorder), shape: BoxShape.circle),
                            child: Icon(iconAccent, size: 24, color: arrowAccent.withOpacity(0.9)),
                          ),
                        ],
                      ),
                      Text('${item['total']} ${AppLocalizations.of(context)!.translate(item['subKey'])}', style: TextStyle(fontSize: 17, color: c.subText)),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(right: 110),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.chip, borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: c.isDark ? Colors.transparent : AppPalette.shadow(Colors.white), blurRadius: 15, offset: Offset(0, 6))], border: Border.all(width: 1, color: c.cardBorder)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$learned/$total', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
                                  _buildBadge(context, item['status']),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(AppLocalizations.of(context)!.translate(item['letter']), style: TextStyle(color: AppPalette.fg(Colors.grey.shade500), fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: AppPalette.bg(Color(0xFF42A5F5)).withOpacity(0.3), valueColor: AlwaysStoppedAnimation(AppPalette.fg(Color(0xFF4A7FE0)))),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: AppPalette.fg(Colors.grey)))
                                ]
                              )
                            ]
                          )
                        )
                      )
                    ]
                  )
                )
              ]
            )
          ),
          Positioned(right: (item['imageRight'] ?? 0).toDouble(), bottom: (item['imageBottom'] ?? 0).toDouble(), child: item['imageUrl'] != null
            // Textbooks from the dashboard: cover uploaded to the server, the book picture if it can't load
            ? Image.network(item['imageUrl'], width: (item['imageWidth'] ?? 115).toDouble(), errorBuilder: (_, _, _) => Image.asset(item['image'], width: (item['imageWidth'] ?? 115).toDouble()))
            : Image.asset(item['image'], width: (item['imageWidth'] ?? 115).toDouble()))
        ],
      ),
    );
  }

  static Widget _buildBadge(BuildContext context, LessonStatus status) {
    late Color bg, fg;
    late IconData icon;
    late String key;

    switch (status) {
      case LessonStatus.passed: bg = AppPalette.auto(Color(0xFFD7F5DD)); fg = AppPalette.auto(Color(0xFF2E9E4F)); icon = Icons.check_circle; key = 'passed'; break;
      case LessonStatus.opened: bg = AppPalette.auto(Color(0xFFFBF8CC)); fg = AppPalette.auto(Color(0xFF8A7A00)); icon = Icons.lock_open; key = 'opened'; break;
      case LessonStatus.locked: bg = AppPalette.auto(Color(0xFFFAD4D4)); fg = AppPalette.auto(Color(0xFFD64545)); icon = Icons.lock; key = 'locked'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg), const SizedBox(width: 4),
          Text(AppLocalizations.of(context)!.translate(key), style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class BuildAllLessons {
  static Widget buildAllLessons(BuildContext context, Map<String, dynamic> item){
    final LessonStatus status = item['status'] as LessonStatus;
    final Color accent = switch (status) {
      LessonStatus.passed => AppPalette.auto(Color(0xFF2E9E4F)),
      LessonStatus.opened => AppPalette.auto(Color(0xFF42A5F5)).withOpacity(0.9),
      LessonStatus.locked => AppPalette.auto(Color(0xFFB0BEC5)),
    };

    final Color arrowAccent = switch (status) {
      LessonStatus.passed => AppPalette.auto(Color(0xFF2E9E4F)),
      LessonStatus.opened => AppPalette.auto(Color(0xFF42A5F5)).withOpacity(0.9),
      LessonStatus.locked => AppPalette.auto(Color(0xFFB0BEC5)),
    };

    final IconData iconAccent = switch (status) {
      LessonStatus.passed => Icons.done,
      LessonStatus.opened => Icons.keyboard_arrow_right,
      LessonStatus.locked => Icons.lock,
    };

    final c = AppColors.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: c.cardBorder), boxShadow: [BoxShadow(color: accent.withValues(alpha: c.isDark ? 0.3 : 0.9), blurRadius: 15)]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
                  // 'imageUrl': a lesson picture from the dashboard
                  child: item['imageUrl'] != null
                    ? Image.network(item['imageUrl'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Image.asset(item['image'] ?? '', width: 60, height: 60, errorBuilder: (c, e, s) => const Icon(Icons.store, size: 30)))
                    : Image.asset(item['image'], width: 60, height: 60, fit: BoxFit.scaleDown, errorBuilder: (c, e, s) => const Icon(Icons.store, size: 30)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBadge(context, item['status']), const SizedBox(height: 4),
                      Text(item['titleKey'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Image.asset(item['imageTime'], width: 16, height: 16), const SizedBox(width: 6),
                          Flexible(child: Text(item['time'], maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8),
                          Image.asset(item['imageHand'], width: 16, height: 16, color: AppPalette.fg(Color(0x80020B14))), const SizedBox(width: 6),
                          Flexible(child: Text(item['click'], maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
            child: Center(child: Icon(iconAccent, size: 24, color: arrowAccent.withValues(alpha: 0.9))),
          ),
        ],
      ),
    );
  }

  static Widget _buildBadge(BuildContext context, LessonStatus status) {
    late Color bg, fg;
    late IconData icon;
    late String key;

    switch (status) {
      case LessonStatus.passed: bg = AppPalette.auto(Color(0xFFD7F5DD)); fg = AppPalette.auto(Color(0xFF2E9E4F)); icon = Icons.check_circle; key = 'passed'; break;
      case LessonStatus.opened: bg = AppPalette.auto(Color(0xFFFBF8CC)); fg = AppPalette.auto(Color(0xFF8A7A00)); icon = Icons.lock_open; key = 'opened'; break;
      case LessonStatus.locked: bg = AppPalette.auto(Color(0xFFFAD4D4)); fg = AppPalette.auto(Color(0xFFD64545)); icon = Icons.lock; key = 'locked'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg), const SizedBox(width: 4),
          Text(AppLocalizations.of(context)!.translate(key), style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class BuildTranslation {
  static Widget buildTrans(BuildContext context, Map<String, dynamic> item){
    final LessonStatus status = item['status'] as LessonStatus;
    final Color accent = switch (status) {
      LessonStatus.passed => AppPalette.auto(Color(0xFF2E9E4F)),
      LessonStatus.opened => AppPalette.auto(Color(0xFF42A5F5)).withValues(alpha: 0.9),
      LessonStatus.locked => AppPalette.auto(Color(0xFFB0BEC5)),
    };

    final Color arrowAccent = switch (status) {
      LessonStatus.passed => AppPalette.auto(Color(0xFF2E9E4F)),
      LessonStatus.opened => AppPalette.auto(Color(0xFF42A5F5)).withValues(alpha: 0.9),
      LessonStatus.locked => AppPalette.auto(Color(0xFFB0BEC5)),
    };

    final IconData iconAccent = switch (status) {
      LessonStatus.passed => Icons.done,
      LessonStatus.opened => Icons.keyboard_arrow_right,
      LessonStatus.locked => Icons.lock,
    };

    final c = AppColors.of(context);

    return Container(
      clipBehavior: Clip.antiAlias, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: c.cardBorder), boxShadow: [BoxShadow(color: accent.withValues(alpha: c.isDark ? 0.3 : 0.9), blurRadius: 15)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
                  child: Image.asset(item['image'], width: 30, height: 30, fit: BoxFit.scaleDown, errorBuilder: (c, e, s) => const Icon(Icons.store, size: 30)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBadge(context, item['status']), const SizedBox(height: 4),
                      Text(item['titleKey'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(item['subKey'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
            child: Center(child: Icon(iconAccent, size: 24, color: arrowAccent.withValues(alpha: 0.9))),
          ),
        ],
      ),
    );
  }

  static Widget _buildBadge(BuildContext context, LessonStatus status) {
    late Color bg, fg;
    late IconData icon;
    late String key;

    switch (status) {
      case LessonStatus.passed: bg = AppPalette.auto(Color(0xFFD7F5DD)); fg = AppPalette.auto(Color(0xFF2E9E4F)); icon = Icons.check_circle; key = 'passed'; break;
      case LessonStatus.opened: bg = AppPalette.auto(Color(0xFFFBF8CC)); fg = AppPalette.auto(Color(0xFF8A7A00)); icon = Icons.lock_open; key = 'opened'; break;
      case LessonStatus.locked: bg = AppPalette.auto(Color(0xFFFAD4D4)); fg = AppPalette.auto(Color(0xFFD64545)); icon = Icons.lock; key = 'locked'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(AppLocalizations.of(context)!.translate(key), style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
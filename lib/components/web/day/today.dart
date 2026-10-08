import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/main.dart';

import '../../../l10n/app_localizations.dart';
import 'fireStreak.dart';

import 'package:signlang/services/theme_service.dart';

class StreakResult {
  final int count;
  final bool increased;
  StreakResult(this.count, this.increased);
}

/// "Great!" screen shown once a day after the first finished lesson: streak flame + this week's progress.
/// [viewOnly] (opened from Profile) only shows the streak: it doesn't record today as completed.
class Today extends StatefulWidget {
  final bool viewOnly;
  const Today({super.key, this.viewOnly = false});

  @override
  State<Today> createState() => _TodayState();
}

class _TodayState extends State<Today> with SingleTickerProviderStateMixin {
  static const Color _blue = Color(0xFF4A7FD0);
  static const Color _blueLight = Color(0xFF5B93E8);

  final int _todayWeekday = DateTime.now().weekday;
  int _streak = 0;
  bool _hot = false;
  Set<int> _completedDays = {};

  late final AnimationController _enter = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);

  @override
  void initState() { super.initState(); _loadStreak(); }

  @override
  void dispose() { _enter.dispose(); super.dispose(); }

  Future<void> _loadStreak() async {
    // lessonsOver has usually recorded today already; recordCompletion is then a no-op that just returns the count
    final int count = widget.viewOnly ? await StreakManager.currentStreak() : (await StreakManager.recordCompletion()).count;
    final done = await StreakManager.completedWeekdaysThisWeek();
    if (!mounted) return;
    setState(() { _streak = count; _completedDays = done; _hot = done.contains(_todayWeekday); });
    _enter.forward();
  }

  void _handleContinue() {
    if (widget.viewOnly) { Navigator.pop(context); return; }
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainWrapper(initialTab: 0)), (route) => route.isFirst);
  }

  void _handleShare() {
    final loc = AppLocalizations.of(context)!;
    SharePlus.instance.share(ShareParams(text: '${loc.translate('streak_share').replaceAll('{n}', '$_streak')} 🔥\n\nhttps://play.google.com/store/apps/details?id=com.example.signlang'));
  }

  // staggered fade + slide-up for each block, [start] in 0..1 of the entrance animation
  Widget _reveal(double start, Widget child) {
    final anim = CurvedAnimation(parent: _enter, curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    const String imageDay = 'web/images/to_day.png';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // ===== 1) image =====
                      _reveal(0.0, Image.asset(imageDay, height: 200)),
                      const SizedBox(height: 8),
                      // ===== 2) streak =====
                      _reveal(0.15, Column(
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: _streak),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => FireStreak(streak: value, hot: _hot, size: 104),
                          ),
                          const SizedBox(height: 6),
                          Text(loc.translate('day_streak'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: AppPalette.fg(const Color(0xFFE65100)))),
                        ],
                      )),
                      const SizedBox(height: 20),
                      // ===== 3) text =====
                      _reveal(0.3, Column(
                        children: [
                          Text(loc.translate(widget.viewOnly ? 'weekly_study' : 'great'), textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.text)),
                          if (!widget.viewOnly) ...[
                            const SizedBox(height: 6),
                            Text(loc.translate('great_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.4, color: c.subText)),
                          ],
                        ],
                      )),
                      const SizedBox(height: 24),
                      // ===== 4) week =====
                      _reveal(0.45, _weekCard(loc, c)),
                      const Spacer(),
                      const SizedBox(height: 24),
                      // ===== 5) buttons =====
                      _reveal(0.6, Column(
                        children: [
                          SizedBox(
                            width: double.infinity, height: 56,
                            child: ElevatedButton(
                              onPressed: _handleContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPalette.bg(_blue).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), shadowColor: AppPalette.shadow(const Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                                side: BorderSide(width: 1, color: AppPalette.border(const Color(0xFF1A237E)).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(loc.translate('continue'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.fg(Colors.blue[900]!))),
                                  const SizedBox(width: 10),
                                  Icon(Icons.arrow_forward_outlined, color: AppPalette.fg(Colors.blue[900]!), size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity, height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _handleShare,
                              icon: Icon(Icons.share, size: 18, color: AppPalette.fg(const Color(0xFF334155))),
                              label: Text(loc.translate('great_sub_title'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.fg(const Color(0xFF334155)))),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppPalette.bg(const Color(0xFF424242)).withValues(alpha: 0.06),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                side: BorderSide(width: 1, color: AppPalette.border(const Color(0xFF212121)).withValues(alpha: 0.2)),
                              ),
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _weekCard(AppLocalizations loc, AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.cardBorder),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.translate('weekly_streak'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (index) {
              final int weekday = index + 1;
              return Expanded(child: _dayCell(loc.translate('day_short_$weekday'), done: _completedDays.contains(weekday), isToday: weekday == _todayWeekday, c: c));
            }),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(String label, {required bool done, required bool isToday, required AppColors c}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: isToday ? AppPalette.fg(_blue) : c.subText)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          height: 36, width: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppPalette.bg(_blueLight), AppPalette.bg(_blue)]) : null,
            color: done ? null : c.track.withValues(alpha: 0.5),
            border: isToday && !done ? Border.all(color: AppPalette.border(_blueLight), width: 2) : null,
            boxShadow: done ? [BoxShadow(color: AppPalette.shadow(_blueLight).withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
        ),
      ],
    );
  }
}

class StreakManager {
  static const _kCount = 'streak_count';
  static const _kLastDate = 'streak_last_date';
  static const _kCompletedDays = 'completed_days';
  static const _kShownDate = 'today_shown_date';

  /// Marks today as completed. Safe to call more than once a day: later calls return increased = false.
  static Future<StreakResult> recordCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(DateTime.now());
    final todayStr = _fmt(today);

    final lastStr = prefs.getString(_kLastDate);
    int count = prefs.getInt(_kCount) ?? 0;

    // record today's date in the completed set
    final days = prefs.getStringList(_kCompletedDays) ?? [];
    if (!days.contains(todayStr)) { days.add(todayStr); await prefs.setStringList(_kCompletedDays, days); }

    if (lastStr == todayStr) return StreakResult(count, false);
    if (lastStr != null) {
      final diff = today.difference(DateTime.parse(lastStr)).inDays;
      count = diff == 1 ? count + 1 : 1;
    } else {
      count = 1;
    }
    await prefs.setInt(_kCount, count);
    await prefs.setString(_kLastDate, todayStr);
    return StreakResult(count, true);
  }

  /// Current streak without changing anything: 0 once a whole day has been missed.
  static Future<int> currentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_kLastDate);
    if (lastStr == null) return 0;
    final diff = _dateOnly(DateTime.now()).difference(DateTime.parse(lastStr)).inDays;
    return diff <= 1 ? prefs.getInt(_kCount) ?? 0 : 0;
  }

  static Future<bool> alreadyShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kShownDate) == _fmt(_dateOnly(DateTime.now()));
  }

  static Future<void> markShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kShownDate, _fmt(_dateOnly(DateTime.now())));
  }

  /// Weekdays (1 = Mon ... 7 = Sun) of the current week that have a completed lesson.
  static Future<Set<int>> completedWeekdaysThisWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getStringList(_kCompletedDays) ?? [];
    final now = _dateOnly(DateTime.now());
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return {
      for (final s in days)
        if (!DateTime.parse(s).isBefore(monday) && !DateTime.parse(s).isAfter(sunday)) DateTime.parse(s).weekday,
    };
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

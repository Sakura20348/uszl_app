import 'package:shared_preferences/shared_preferences.dart';

/// One achievement: its artwork, texts and the task that opens it ([target] reached by [progress]).
class AchievementDef {
  final String id;
  final String image;
  final String titleKey;
  final String taskKey; // what the person has to do, shown while it is closed
  final String doneKey; // shown once it is opened
  final int target;
  final int Function(SharedPreferences prefs) progress;

  const AchievementDef({required this.id, required this.image, required this.titleKey, required this.taskKey, required this.doneKey, required this.target, required this.progress});
}

/// Works out achievement progress from the stats the app already saves, and remembers which are opened.
/// An achievement never closes again once opened (e.g. after a streak is lost).
class AchievementService {
  static final AchievementService instance = AchievementService._();
  AchievementService._();

  static const _kUnlocked = 'ach_unlocked';
  static const _kNew = 'ach_new';
  static const _kNight = 'ach_night_lesson';
  static const _kPerfect = 'ach_perfect_lesson';

  static int _streak(SharedPreferences p) {
    final a = p.getInt('streak_count') ?? 0, b = p.getInt('stat_streak_record') ?? 0;
    return a > b ? a : b;
  }

  static int _learnedSigns(SharedPreferences p) =>
      (p.getStringList('lp_learned') ?? []).fold(0, (sum, e) => sum + (int.tryParse(e.split(':').last) ?? 0));

  static int _learnedOf(SharedPreferences p, String id) {
    for (final e in p.getStringList('lp_learned') ?? []) {
      final parts = e.split(':');
      if (parts.length == 2 && parts[0] == id) return int.tryParse(parts[1]) ?? 0;
    }
    return 0;
  }

  static int _goalDays(SharedPreferences p) => (p.getStringList('stat_goal_days') ?? []).length;
  static int _flag(SharedPreferences p, String key) => (p.getBool(key) ?? false) ? 1 : 0;

  static final List<AchievementDef> all = [
    AchievementDef(id: '0', image: 'web/images/fire.png', titleKey: 'day_series', taskKey: 'ach_task_0', doneKey: 'day_series_sub', target: 7, progress: _streak),
    AchievementDef(id: '1', image: 'web/images/books.png', titleKey: 'spelling_learner', taskKey: 'ach_task_1', doneKey: 'ach_done_1', target: 50, progress: _learnedSigns),
    AchievementDef(id: '2', image: 'web/images/accuracy.png', titleKey: 'daily_goal', taskKey: 'ach_task_2', doneKey: 'ach_done_2', target: 1, progress: _goalDays),
    AchievementDef(id: '3', image: 'web/images/night_learner.png', titleKey: 'night_learner', taskKey: 'ach_task_3', doneKey: 'ach_done_3', target: 1, progress: (p) => _flag(p, _kNight)),
    AchievementDef(id: '4', image: 'web/images/electrical.png', titleKey: 'goal_days_7', taskKey: 'ach_task_4', doneKey: 'ach_done_4', target: 7, progress: _goalDays),
    AchievementDef(id: '5', image: 'web/images/cyan_jewel.png', titleKey: 'perfect_level', taskKey: 'ach_task_5', doneKey: 'ach_done_5', target: 20, progress: (p) => (p.getStringList('lp_completed') ?? []).length),
    AchievementDef(id: '6', image: '', titleKey: 'spelling_100', taskKey: 'ach_task_6', doneKey: 'ach_done_6', target: 100, progress: _learnedSigns),
    AchievementDef(id: '7', image: 'web/images/star.png', titleKey: 'perfect_score', taskKey: 'ach_task_7', doneKey: 'ach_done_7', target: 1, progress: (p) => _flag(p, _kPerfect)),
    AchievementDef(id: '8', image: 'web/images/calendar.png', titleKey: 'streak_30', taskKey: 'ach_task_8', doneKey: 'ach_done_8', target: 30, progress: _streak),
    AchievementDef(id: '9', image: 'web/images/fire_hot.png', titleKey: 'alphabet_master', taskKey: 'ach_task_9', doneKey: 'ach_done_9', target: 28, progress: (p) => _learnedOf(p, '0')),
  ];

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async => _prefs ??= await SharedPreferences.getInstance();

  /// Call when a lesson is finished. [perfect] = finished without a single mistake.
  Future<void> recordLessonFinished({required bool perfect}) async {
    final p = await _p;
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 5) await p.setBool(_kNight, true);
    if (perfect) await p.setBool(_kPerfect, true);
  }

  /// Opens every achievement whose task is done. Returns the ids that just opened.
  Future<List<String>> refresh() async {
    final p = await _p;
    final unlocked = (p.getStringList(_kUnlocked) ?? []).toSet();
    final fresh = [for (final a in all) if (!unlocked.contains(a.id) && a.progress(p) >= a.target) a.id];
    if (fresh.isNotEmpty) {
      await p.setStringList(_kUnlocked, [...unlocked, ...fresh]);
      await p.setStringList(_kNew, {...?p.getStringList(_kNew), ...fresh}.toList());
    }
    return fresh;
  }

  bool isUnlocked(String id) => (_prefs?.getStringList(_kUnlocked) ?? const []).contains(id);
  bool isNew(String id) => (_prefs?.getStringList(_kNew) ?? const []).contains(id);
  int progressOf(AchievementDef a) => _prefs == null ? 0 : a.progress(_prefs!).clamp(0, a.target);

  /// The person has seen this opened achievement: drop its "New!" mark.
  Future<void> markSeen(String id) async {
    final p = await _p;
    await p.setStringList(_kNew, (p.getStringList(_kNew) ?? []).where((e) => e != id).toList());
  }
}

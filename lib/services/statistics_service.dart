import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'dart:convert';
import '../models/statistics.dart';

class StatisticsService {
  static final StatisticsService instance = StatisticsService._();
  StatisticsService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    syncPeriods();
  }

  /// Starts the "today" counters from 0 on a new day, and the per-weekday counters on a new week (Monday).
  void syncPeriods() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final todayStr = today.toIso8601String();
    if (_prefs.getString('stat_day') != todayStr) {
      _prefs.remove('stat_minutes_today');
      _prefs.remove('stat_points_today');
      _prefs.remove('stat_lessons_today');
      _prefs.setString('stat_day', todayStr);
    }

    final mondayStr = monday.toIso8601String();
    if (_prefs.getString('stat_week') != mondayStr) {
      _prefs.remove('stat_minutes_history');
      _prefs.remove('stat_weekly_status');
      _prefs.setString('stat_week', mondayStr);
    }
  }

  UserStatistics getStatistics() {
    syncPeriods();
    
    final completedLessons = _prefs.getStringList('lp_completed')?.length ?? 0;
    // ... rest of method
    final lessonsIncrement = _prefs.getInt('stat_lessons_today') ?? 0;
    
    final accuracy = _prefs.getDouble('stat_accuracy') ?? 0.85; // Default high accuracy for now
    final accuracyIncrement = _prefs.getDouble('stat_accuracy_today') ?? 0.05;
    
    // Use StreakManager's keys
    final weeklyStreak = _prefs.getInt('streak_count') ?? 0;
    final streakRecord = _prefs.getInt('stat_streak_record') ?? weeklyStreak;
    if (weeklyStreak > streakRecord) {
      _prefs.setInt('stat_streak_record', weeklyStreak);
    }
    
    final collectedPoints = _prefs.getInt('stat_points_total') ?? 0;
    final pointsIncrement = _prefs.getInt('stat_points_today') ?? 0;
    
    final dailyGoalMinutes = _prefs.getInt('stat_daily_goal') ?? 10;
    final currentDailyMinutes = _prefs.getInt('stat_minutes_today') ?? 0;
    
    // Weekly status (Mon-Sun) - Sync with StreakManager's completed_days
    final completedDaysList = _prefs.getStringList('completed_days') ?? [];
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    
    List<bool> weeklyStudyStatus = List.filled(7, false);
    for (final s in completedDaysList) {
      try {
        final d = DateTime.parse(s);
        if (!d.isBefore(monday) && !d.isAfter(monday.add(const Duration(days: 6)))) {
          weeklyStudyStatus[d.weekday - 1] = true;
        }
      } catch (_) {}
    }
    
    // Daily minutes history
    final historyList = _prefs.getStringList('stat_minutes_history') ?? List.filled(7, '0');
    final dailyMinutesHistory = historyList.map((e) => int.tryParse(e) ?? 0).toList();
    
    // Activity calendar of this week, like the server's
    final activityHeatmap = activityCalendar('week').cells;

    return UserStatistics(
      completedLessons: completedLessons,
      lessonsIncrement: lessonsIncrement,
      accuracy: accuracy,
      accuracyIncrement: accuracyIncrement,
      weeklyStreak: weeklyStreak,
      streakRecord: streakRecord,
      collectedPoints: collectedPoints,
      pointsIncrement: pointsIncrement,
      dailyGoalMinutes: dailyGoalMinutes,
      currentDailyMinutes: currentDailyMinutes,
      weeklyStudyStatus: weeklyStudyStatus,
      dailyMinutesHistory: dailyMinutesHistory,
      activityHeatmap: activityHeatmap,
    );
  }

  Future<void> addPoints(int points) async {
    syncPeriods();
    int currentTotal = _prefs.getInt('stat_points_total') ?? 0;
    int currentToday = _prefs.getInt('stat_points_today') ?? 0;
    await _prefs.setInt('stat_points_total', currentTotal + points);
    await _prefs.setInt('stat_points_today', currentToday + points);
  }

  Future<void> addStudyTime(int minutes) async {
    syncPeriods();
    int currentToday = _prefs.getInt('stat_minutes_today') ?? 0;
    await _prefs.setInt('stat_minutes_today', currentToday + minutes);

    // remember each day the daily goal was reached (used by achievements)
    final int goal = _prefs.getInt('stat_daily_goal') ?? 10;
    if (currentToday < goal && currentToday + minutes >= goal) {
      final days = _prefs.getStringList('stat_goal_days') ?? [];
      final todayStr = _prefs.getString('stat_day') ?? '';
      if (!days.contains(todayStr)) await _prefs.setStringList('stat_goal_days', [...days, todayStr]);
    }
    
    // Update weekly status for today
    int weekday = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    List<String> weeklyStatus = _prefs.getStringList('stat_weekly_status') ?? List.filled(7, 'false');
    weeklyStatus[weekday - 1] = 'true';
    await _prefs.setStringList('stat_weekly_status', weeklyStatus);
    
    // Update history
    List<String> history = _prefs.getStringList('stat_minutes_history') ?? List.filled(7, '0');
    int historyVal = (int.tryParse(history[weekday - 1]) ?? 0) + minutes;
    history[weekday - 1] = historyVal.toString();
    await _prefs.setStringList('stat_minutes_history', history);

    // When it was learned, for the activity calendar
    await _logSession(minutes);
  }

  // ===== activity calendar: minutes by time of day and weekday, as on the server =====
  /// Starting hours of the calendar's rows, top to bottom (same as the server's SLOT_HOURS)
  static const List<int> slotHours = [22, 19, 16, 13, 10, 7, 4, 0];
  static const _sessionsKey = 'stat_sessions';

  // Each study session as "2026-10-08T14:05:00.000|5" (start, minutes); one year is kept
  Future<void> _logSession(int minutes) async {
    final now = DateTime.now();
    final yearAgo = now.subtract(const Duration(days: 366));
    final log = (_prefs.getStringList(_sessionsKey) ?? [])
        .where((e) => DateTime.tryParse(e.split('|').first)?.isAfter(yearAgo) ?? false)
        .toList()
      ..add('${now.toIso8601String()}|$minutes');
    await _prefs.setStringList(_sessionsKey, log);
  }

  /// Minutes per time slot (rows, [slotHours]) and weekday (columns, Monday first), row by row (8 x 7),
  /// and how many weeks they cover: [period] 'week' = this week, 'month' = last 28 days, 'year' = last 52 weeks.
  ({List<double> cells, int weeks}) activityCalendar(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final (DateTime from, int weeks) = switch (period) {
      'month' => (today.subtract(const Duration(days: 27)), 4),
      'year' => (today.subtract(const Duration(days: 52 * 7 - 1)), 52),
      _ => (today.subtract(Duration(days: today.weekday - 1)), 1),
    };
    final cells = List<double>.filled(slotHours.length * 7, 0);
    for (final entry in _prefs.getStringList(_sessionsKey) ?? const <String>[]) {
      final parts = entry.split('|');
      final start = DateTime.tryParse(parts.first);
      if (start == null || start.isBefore(from) || parts.length < 2) continue;
      final row = slotHours.indexWhere((h) => start.hour >= h);
      cells[row * 7 + start.weekday - 1] += double.tryParse(parts[1]) ?? 0;
    }
    return (cells: cells, weeks: weeks);
  }

  Future<void> setDailyGoal(int minutes) async {
    await _prefs.setInt('stat_daily_goal', minutes);
    await _prefs.setBool(_goalSyncedKey, false);
    await syncDailyGoal();
  }

  int get dailyGoal => _prefs.getInt('stat_daily_goal') ?? 10;

  static const _goalSyncedKey = 'stat_daily_goal_synced';

  /// Saves the daily goal on the server once logged in (onboarding sets it before login).
  Future<void> syncDailyGoal() async {
    final goal = _prefs.getInt('stat_daily_goal');
    if (goal == null || (_prefs.getBool(_goalSyncedKey) ?? false) || !await UzslApi.isLoggedIn()) return;
    try {
      await UzslApi.setDailyGoal(goal);
      await _prefs.setBool(_goalSyncedKey, true);
    } on ApiException catch (e) {
      debugPrint('Daily goal not saved on the server: $e');
    }
  }

  // More methods could be added to update accuracy, streak etc.
}

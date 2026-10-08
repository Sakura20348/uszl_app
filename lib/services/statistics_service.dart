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
    _syncHeatmap(); // Ensure heatmap is shifted if days passed
    
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
    
    // Activity heatmap
    final heatmapList = _prefs.getStringList('stat_heatmap') ?? List.generate(56, (i) => (i % 7 == 0 ? 0.2 : 0.0).toString());
    final activityHeatmap = heatmapList.map((e) => double.tryParse(e) ?? 0.0).toList();

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

    // Update heatmap intensity
    await _updateHeatmap(minutes);
  }

  void _syncHeatmap() {
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final lastSyncStr = _prefs.getString('stat_heatmap_last_sync');
    
    if (lastSyncStr != null) {
      final lastSync = DateTime.parse(lastSyncStr);
      final daysDiff = now.difference(lastSync).inDays;
      
      if (daysDiff > 0) {
        List<String> heatmap = _prefs.getStringList('stat_heatmap') ?? List.filled(56, '0.0');
        // Shift left
        List<String> newHeatmap = List.filled(56, '0.0');
        for (int i = 0; i < 56 - daysDiff; i++) {
          newHeatmap[i] = heatmap[i + daysDiff];
        }
        _prefs.setStringList('stat_heatmap', newHeatmap);
      }
    }
    _prefs.setString('stat_heatmap_last_sync', now.toIso8601String());
  }

  Future<void> _updateHeatmap(int minutes) async {
    _syncHeatmap();
    List<String> heatmap = _prefs.getStringList('stat_heatmap') ?? List.filled(56, '0.0');
    double currentIntensity = double.tryParse(heatmap[55]) ?? 0.0;
    int goal = _prefs.getInt('stat_daily_goal') ?? 10;
    
    double addedIntensity = minutes / goal;
    double newIntensity = (currentIntensity + addedIntensity).clamp(0.0, 1.0);
    
    heatmap[55] = newIntensity.toStringAsFixed(2);
    await _prefs.setStringList('stat_heatmap', heatmap);
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

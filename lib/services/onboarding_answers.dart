import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:signlang/api/uzsl_api.dart';

/// Onboarding answers (why they learn, where they heard about UzSL, daily goal) are given before
/// login, so they are kept on the phone and sent to the server once the user is logged in.
/// The dashboard's Users page shows them (Source, Why they learn, Daily goal).
class OnboardingAnswers {
  OnboardingAnswers._();

  // Same order as WhyUzslData / FromWhereData / HowLongData in nameLogItem.dart,
  // with the values the API expects
  static const learningGoals = ['work', 'education', 'hearing', 'communication', 'curiosity'];
  static const referralSources = ['bloggers', 'google', 'appStore', 'googlePlay', 'youtube', 'instagram', 'telegram', 'other'];
  static const dailyGoals = [5, 10, 15, 20];

  static const _goalKey = 'onboarding_learning_goal';
  static const _sourceKey = 'onboarding_referral_source';
  static const _dailyKey = 'onboarding_daily_goal';
  // Set when the server has the answers, so they are sent only once
  static const _syncedKey = 'onboarding_synced';

  static Future<void> saveLearningGoal(int index) => _save(_goalKey, learningGoals[index]);
  static Future<void> saveReferralSource(int index) => _save(_sourceKey, referralSources[index]);

  static Future<void> saveDailyGoal(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyKey, dailyGoals[index]);
    await prefs.setBool(_syncedKey, false);
  }

  static Future<void> _save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    await prefs.setBool(_syncedKey, false);
  }

  /// Sends the answers, name and app language to the server (after login, and on app start
  /// until it worked). Failures are kept for the next try.
  static Future<void> sync() async {
    if (!await UzslApi.isLoggedIn()) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_syncedKey) ?? false) return;

    final lang = prefs.getString('lang');
    final name = prefs.getString('first_name')?.trim();
    final profile = <String, dynamic>{
      'learningGoal': ?prefs.getString(_goalKey),
      'referralSource': ?prefs.getString(_sourceKey),
      'dailyGoalMinutes': ?prefs.getInt(_dailyKey),
      if (lang == 'uz' || lang == 'ru' || lang == 'en') 'language': lang,
      if (name != null && name.isNotEmpty) 'fullName': name,
      'onboardingCompleted': true,
    };
    try {
      await UzslApi.updateOnboarding(profile);
      await prefs.setBool(_syncedKey, true);
    } on ApiException catch (e) {
      debugPrint('Onboarding answers not sent: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/profile/nameProfile/nameStore.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'package:signlang/services/firebase_setup.dart';
import 'package:signlang/services/lesson_sync.dart';
import 'package:signlang/services/notification_center.dart';
import 'package:signlang/services/push_service.dart';
import 'package:signlang/services/saved_accounts.dart';
import 'package:signlang/services/statistics_service.dart';

/// Makes the progress saved on this phone belong to the account that is logged in.
///
/// Lessons, statistics, streak, achievements, name and photo are kept on the phone. Without this,
/// whoever logs in next on the same phone would see the previous person's progress.
class AccountService {
  AccountService._();

  static const _ownerKey = 'local_owner_user_id';

  /// Phone settings that are not personal: kept when the account changes
  static const _keep = {
    'lang', 'isLanguageSelected', 'selected_language_index', 'themeMode', 'onboarding_done', 'noInternet',
    'push_permission_asked', 'isLoggedIn', 'tabIndex', 'api_access_token', 'api_refresh_token', _ownerKey,
    SavedAccounts.key,
  };

  /// Right after a login: if another account used this phone before, its data is removed first.
  /// Then the account's progress from the server is added.
  /// With [method], the account is remembered on the "Saved accounts" screen.
  static Future<void> afterLogin(BuildContext context, {LoginMethod? method}) async {
    try {
      final me = await UzslApi.me();
      final id = me['id'] as int;
      if (method != null) await SavedAccounts.remember(me, method);
      final prefs = await SharedPreferences.getInstance();
      final owner = prefs.getInt(_ownerKey);
      if (owner != null && owner != id) await _clearPersonalData();
      await prefs.setInt(_ownerKey, id);
      if (context.mounted) await restoreFromServer(context, me);
    } on ApiException catch (e) {
      debugPrint('Account progress not loaded: $e');
    }
  }

  /// Completed lessons, name and daily goal from the server.
  static Future<void> restoreFromServer(BuildContext context, Map<String, dynamic> me) async {
    final completed = await UzslApi.completedBuiltinLessons();
    LessonProgress.instance.restoreCompleted(completed);
    if (context.mounted) LessonProgress.instance.recomputeLearned(context);

    final fullName = (me['fullName'] as String?)?.trim() ?? '';
    if (fullName.isNotEmpty && (await NameStorage.load()) == null) {
      final parts = fullName.split(RegExp(r'\s+'));
      await NameStorage.save(parts.first);
      if (parts.length > 1) await LastNameStorage.save(parts.skip(1).join(' '));
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt('stat_daily_goal') == null) {
      await prefs.setInt('stat_daily_goal', me['dailyGoalMinutes'] as int? ?? 10);
      await prefs.setBool('stat_daily_goal_synced', true);
    }
  }

  /// Log out: results still waiting are sent first (they are this person's), then the phone stops
  /// getting this account's pushes and its personal data is removed.
  static Future<void> logout() async {
    // The internet steps run together and get a few seconds each, so a weak connection
    // can't keep the person waiting (each request alone could wait 20 seconds)
    await Future.wait([
      _quick(LessonSync.flush(), 'results'),
      _quick(PushService.unregisterDevice(), 'push token'),
      _quick(UzslApi.goOffline(), 'offline status'),
    ]);
    await _refreshSavedAccount();
    await UzslApi.logout();
    await FirebaseSetup.signOut();
    await _clearPersonalData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ownerKey);
  }

  /// Delete account: the account and its progress are deleted on the server, then the phone is
  /// cleaned like after a log out. If the server can't delete it, this throws and nothing is removed,
  /// so the person can try again.
  static Future<void> deleteAccount() async {
    if (await UzslApi.isLoggedIn()) {
      // the phone's push token goes first, while the account can still remove it
      await _quick(PushService.unregisterDevice(), 'push token');
      await UzslApi.deleteAccount();
      // a deleted account can't be picked again
      final owner = (await SharedPreferences.getInstance()).getInt(_ownerKey);
      if (owner != null) await SavedAccounts.remove(owner);
      await UzslApi.logout();
      await FirebaseSetup.signOut();
    }
    await _clearPersonalData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ownerKey);
  }

  // The name given on the profile screen after the login, for the "Saved accounts" screen
  static Future<void> _refreshSavedAccount() async {
    final owner = (await SharedPreferences.getInstance()).getInt(_ownerKey);
    if (owner == null) return;
    final name = [await NameStorage.load(), await LastNameStorage.load()].whereType<String>().join(' ');
    await SavedAccounts.update(owner, name: name);
  }

  static const _logoutStepTimeout = Duration(seconds: 4);

  static Future<void> _quick(Future<void> step, String what) => step.timeout(_logoutStepTimeout).catchError((Object e) {
    debugPrint('Log out: $what not sent: $e');
  });

  static Future<void> _clearPersonalData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (!_keep.contains(key)) await prefs.remove(key);
    }
    LessonProgress.instance.clearLocal();
    StatisticsService.instance.syncPeriods();
    NotificationCenter.unread.value = 0;
  }
}

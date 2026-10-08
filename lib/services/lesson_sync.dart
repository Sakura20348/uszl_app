import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:signlang/api/uzsl_api.dart';

/// Sends results of the app's own lessons ("alp_0", "num_3", ...) to the server, so progress, XP,
/// streaks and achievements are saved there and show in the dashboard.
/// Results made offline are kept on the phone and sent later.
class LessonSync {
  LessonSync._();

  static const _pendingKey = 'pending_lesson_results';

  static Future<void> report(String lessonKey, {required int correct, required int wrong, required int durationSeconds}) async {
    if (!await UzslApi.isLoggedIn()) return;
    final result = {'key': lessonKey, 'correct': correct, 'wrong': wrong, 'duration': durationSeconds};
    if (!await _send(result)) await _keep(result);
    await flush();
  }

  /// Sends results kept while offline (called on app start and after each lesson).
  static Future<void> flush() async {
    if (!await UzslApi.isLoggedIn()) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? [];
    if (pending.isEmpty) return;
    final left = <String>[];
    for (final raw in pending) {
      if (!await _send(jsonDecode(raw) as Map<String, dynamic>)) left.add(raw);
    }
    await prefs.setStringList(_pendingKey, left);
  }

  /// True when the server took it, or refused it for good (e.g. unknown lesson): nothing to retry.
  static Future<bool> _send(Map<String, dynamic> r) async {
    try {
      await UzslApi.completeBuiltinLesson(r['key'] as String,
          correct: r['correct'] as int, wrong: r['wrong'] as int, durationSeconds: r['duration'] as int);
      return true;
    } on ApiException catch (e) {
      debugPrint('Lesson result not sent (${r['key']}): $e');
      return !(e.isNetwork || e.status >= 500 || e.status == 401);
    }
  }

  static Future<void> _keep(Map<String, dynamic> r) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? [];
    // At most 100 waiting results
    await prefs.setStringList(_pendingKey, [...pending, jsonEncode(r)].take(100).toList());
  }
}

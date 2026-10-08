import 'dart:async';

import 'package:flutter/material.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_lesson_intro.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';

/// The app's textbook lessons ("alp_0", "num_3", ...) have their own screens. When the dashboard gave
/// a lesson exercises, the lesson is played from the server instead, so edits in the dashboard reach
/// learners. Offline, logged out, or no exercises: the app's own screens are used as before.
class BuiltinLessonPlayer {
  BuiltinLessonPlayer._();

  /// Don't keep the learner waiting when the server is slow or unreachable
  static const Duration _lookupTimeout = Duration(seconds: 4);

  /// Plays [key] from the server and returns true, or returns false to use the app's own screens.
  static Future<bool> play(BuildContext context, String key) async {
    if (!await UzslApi.isLoggedIn()) return false;
    ApiLesson lesson;
    try {
      lesson = await UzslApi.builtinLesson(key).timeout(_lookupTimeout);
    } on ApiException {
      return false;
    } on TimeoutException {
      return false;
    }
    if (lesson.exerciseCount == 0 || !context.mounted) return false;

    // "About lesson" first, like every lesson; it opens the player
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ApiLessonIntro(lesson: lesson)));

    // The server saved the result; mark it here too so the next lesson unlocks
    try {
      final after = await UzslApi.builtinLesson(key).timeout(_lookupTimeout);
      if (after.status == 'completed') LessonProgress.instance.markCompletedOnServer(key);
    } on Exception catch (e) {
      debugPrint('Lesson $key progress not checked: $e');
    }
    return true;
  }
}

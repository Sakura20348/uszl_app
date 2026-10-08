import 'package:flutter/widgets.dart';
import 'package:signlang/api/uzsl_api.dart';

/// Times the Dictionary and Translator tabs and sends each visit to the server
/// (dashboard: Learner activity by part of the app). Lesson time is sent when a lesson finishes.
class SessionTracker with WidgetsBindingObserver {
  SessionTracker._();
  static final SessionTracker _instance = SessionTracker._();

  // Shorter visits are just passing through a tab
  static const Duration _minimum = Duration(seconds: 5);

  static String? _source;
  static DateTime? _startedAt;
  static bool _started = false;

  /// Bottom tab index -> part of the app; null for tabs that aren't timed here
  static String? _sourceOf(int tab) => switch (tab) { 1 => 'dictionary', 2 => 'translator', _ => null };

  /// Call when the main screen opens and whenever the tab changes.
  static void tab(int index) {
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addObserver(_instance);
    }
    _finish();
    _source = _sourceOf(index);
    _startedAt = _source == null ? null : DateTime.now();
  }

  /// Sends the running visit (on tab change, leaving the app, log out).
  static void _finish() {
    final source = _source, startedAt = _startedAt;
    _startedAt = null;
    if (source == null || startedAt == null) return;
    final endedAt = DateTime.now();
    if (endedAt.difference(startedAt) < _minimum) return;
    UzslApi.reportSession(source, startedAt, endedAt);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _finish();
    } else if (state == AppLifecycleState.resumed && _source != null) {
      _startedAt ??= DateTime.now();
    }
  }

  /// The main screen closed (log out): send the visit and stop.
  static void stop() {
    _finish();
    _source = null;
  }
}

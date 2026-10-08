import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/services/push_service.dart';

/// Live count of unread notifications for the bell's PulseDot.
///
/// Updated right away when a push arrives, every [_interval] while the app is open (so notifications
/// sent from the dashboard show up even without push), and when the app comes back to the front.
/// A notification that arrives while the app is open rings once, with a banner.
class NotificationCenter with WidgetsBindingObserver {
  NotificationCenter._();
  static final NotificationCenter _instance = NotificationCenter._();

  static const Duration _interval = Duration(seconds: 30);

  /// Unread notifications; the bell listens to this
  static final ValueNotifier<int> unread = ValueNotifier(0);

  static Timer? _timer;
  // Newest notification already known, so only newer ones ring
  static int? _newestSeen;
  static bool _started = false;

  /// Starts checking (call once the main screen is shown).
  static void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(_instance);
    _timer = Timer.periodic(_interval, (_) => refresh());
    refresh(alert: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timer ??= Timer.periodic(_interval, (_) => refresh());
      // Pushes that came while away were already shown (and rang) by the phone
      refresh(alert: false);
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Gets the unread count from the server. With [alert], new notifications ring and show a banner.
  static Future<void> refresh({bool alert = true}) async {
    if (!await UzslApi.isLoggedIn()) {
      unread.value = 0;
      return;
    }
    try {
      final page = await UzslApi.unreadNotifications(limit: 10);
      final previous = _newestSeen;
      final newest = page.items.isEmpty ? null : page.items.map((n) => n.id).reduce((a, b) => a > b ? a : b);
      if (alert && previous != null) {
        final fresh = page.items.where((n) => n.id > previous).toList();
        if (fresh.isNotEmpty) HapticFeedback.mediumImpact();
        for (final n in fresh.reversed) {
          await PushService.announce(n);
        }
      }
      if (newest != null && (previous == null || newest > previous)) _newestSeen = newest;
      _newestSeen ??= 0;
      unread.value = page.total;
    } on ApiException catch (e) {
      debugPrint('Unread notifications not updated: $e');
    }
  }
}

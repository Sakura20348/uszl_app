import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/web/notification/notification.dart';
import 'package:signlang/services/app_sheets.dart';
import 'package:signlang/services/firebase_setup.dart';
import 'package:signlang/services/notification_center.dart';

/// Push notifications (Firebase Cloud Messaging).
///
/// Needs android/app/google-services.json (and ios/Runner/GoogleService-Info.plist for iOS)
/// from the Firebase console. Without them [init] turns push off and the app works as before:
/// notifications still show in the app's notification list.
class PushService {
  PushService._();

  /// Must match the backend's FCM_ANDROID_CHANNEL and the manifest's default channel
  static const String channelId = 'uzsl_default';
  static const String _askedKey = 'push_permission_asked';

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static bool _enabled = false;
  static bool _mainReady = false;
  // A tapped notification waiting until the main screen is shown (e.g. after the splash)
  static String? _pendingOpen;

  static bool get enabled => _enabled;

  /// Call after [FirebaseSetup.init].
  static Future<void> init() async {
    // Notifications shown by the app itself (sound + banner) work even without Firebase
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
      onDidReceiveNotificationResponse: (response) => _open(response.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          channelId, 'UzSL',
          description: 'Lessons, reminders and news',
          importance: Importance.high,
        ));
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) _open(launch!.notificationResponse?.payload);

    if (!FirebaseSetup.ready) return;
    _enabled = true;
    final messaging = FirebaseMessaging.instance;
    // iOS shows pushes itself while the app is open; Android needs a local notification
    await messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showWhileOpen);
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _open(message.data['notificationId'] as String?));
    messaging.onTokenRefresh.listen((token) => _sendToken(token));

    // Opened by tapping a push while the app was closed
    final initial = await messaging.getInitialMessage();
    if (initial != null) _open(initial.data['notificationId'] as String?);
  }

  /// Shows the system "Allow notifications?" question (once; Android 13+ and iOS).
  static Future<bool> requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
    if (!_enabled) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    final allowed = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (allowed) await registerDevice();
    return allowed;
  }

  /// Remembers that the user chose "Later" in onboarding, so login doesn't ask again.
  static Future<void> skipPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }

  /// After login: asks for permission unless the user already answered in onboarding.
  static Future<void> afterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) ?? false) {
      await registerDevice();
    } else {
      await requestPermission();
    }
  }

  /// Sends this phone's push token to the server, so pushes for the logged-in user reach it.
  static Future<void> registerDevice() async {
    if (!_enabled || !await UzslApi.isLoggedIn()) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToken(token);
    } catch (e) {
      debugPrint('Push token not available: $e');
    }
  }

  static Future<void> _sendToken(String token) async {
    if (!await UzslApi.isLoggedIn()) return;
    try {
      await UzslApi.registerDevice(token, Platform.isIOS ? 'ios' : 'android');
    } on ApiException catch (e) {
      debugPrint('Push token not saved: $e');
    }
  }

  /// On log out: this phone stops getting the user's pushes.
  static Future<void> unregisterDevice() async {
    if (!_enabled) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && await UzslApi.isLoggedIn()) await UzslApi.removeDevice(token);
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Push token not removed: $e');
    }
  }

  // ======================== showing and opening ========================
  // Notifications already shown with sound, so the same one never rings twice
  static final Set<String> _shown = {};

  static Future<void> _showWhileOpen(RemoteMessage message) async {
    final notification = message.notification;
    final id = message.data['notificationId'] as String?;
    if (id != null) _shown.add(id);
    // The bell's PulseDot shows the new one right away
    NotificationCenter.refresh(alert: false);
    if (notification == null || Platform.isIOS) return;
    await _showLocal(message.hashCode, notification.title, notification.body, id);
  }

  /// A notification that arrived while the app is open but not by push (found by [NotificationCenter]):
  /// shown with sound and a banner, once.
  static Future<void> announce(AppNotification n) async {
    if (!_shown.add('${n.id}')) return;
    await _showLocal(n.id, n.title, n.body, '${n.id}');
  }

  static Future<void> _showLocal(int id, String? title, String? body, String? payload) async {
    try {
      await _local.show(
        id, title, body,
        const NotificationDetails(
          android: AndroidNotificationDetails(channelId, 'UzSL', importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Notification not shown: $e');
    }
  }

  static void _open(String? notificationId) {
    if (notificationId == null) return;
    if (!_mainReady) {
      _pendingOpen = notificationId;
      return;
    }
    AppSheets.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => NotificationScreen(openNotificationId: int.tryParse(notificationId))),
    );
  }

  /// Called by the main screen once it is shown: opens a notification tapped during startup.
  static void mainScreenReady() {
    _mainReady = true;
    final pending = _pendingOpen;
    _pendingOpen = null;
    if (pending != null) _open(pending);
  }

  static void mainScreenGone() => _mainReady = false;
}

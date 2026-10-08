import 'package:flutter/material.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/log/langguageChoose.dart';
import '../components/web/connectivity/noInternetSheet.dart';
import '../components/web/error/errorSheet.dart';
import '../components/web/sessionEnded/sessionEnedSheet.dart';
import '../components/web/update/updateSheet.dart';

/// Shows the app-wide status sheets (no internet, server error, session ended, update)
/// from anywhere — services included — without needing a BuildContext.
class AppSheets {
  AppSheets._();

  /// Attached to MaterialApp so sheets can be opened above every route.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String storeUrl = 'https://play.google.com/store/apps/details?id=com.example.signlang';

  /// Attached to MaterialApp.navigatorObservers to track the sheet routes.
  static final NavigatorObserver observer = _SheetObserver();

  // Sheets currently on screen (id → its route), so each one opens at most once.
  static final Map<String, Route<dynamic>?> _open = {};
  static Route<dynamic>? _lastPushed;

  /// Called when the no-internet sheet was removed by navigation (not closed by
  /// the user), e.g. the splash replacing every route; the gate re-checks then.
  static VoidCallback? onNoInternetRemoved;

  static BuildContext? get _context => navigatorKey.currentContext;

  static Future<void> _showOnce(String id, Future<void> Function(BuildContext context) show) async {
    final context = _context;
    if (context == null || _open.containsKey(id)) return;
    _open[id] = null;
    _lastPushed = null;
    final future = show(context); // pushes the sheet route synchronously
    _open[id] = _lastPushed;
    await future;
    _open.remove(id);
  }

  static void _routeGone(Route<dynamic> route, {required bool removed}) {
    final id = _open.entries.where((e) => e.value == route).map((e) => e.key).firstOrNull;
    if (id == null) return;
    _open.remove(id);
    if (removed && id == 'noInternet') {
      WidgetsBinding.instance.addPostFrameCallback((_) => onNoInternetRemoved?.call());
    }
  }

  // ---------------- No internet ----------------
  static Future<void> showNoInternet({required VoidCallback onRetry}) =>
      _showOnce('noInternet', (context) => NoInternetSheet.show(context, onRetry: onRetry));

  /// Closes the no-internet sheet (e.g. when the connection comes back).
  static void hideNoInternet() {
    final route = _open['noInternet'];
    if (route == null || !route.isActive) return;
    _open.remove('noInternet');
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    // Slide it away when it's on top; otherwise drop it from under the newer route.
    route.isCurrent ? navigator.pop() : navigator.removeRoute(route);
  }

  // ---------------- Server error ----------------
  static Future<void> showServerError({VoidCallback? onRetry}) => _showOnce('serverError', (context) {
    return ErrorSheet.show(context, sheet: ErrorSheet.server(onRetry: () {
      navigatorKey.currentState?.pop();
      onRetry?.call();
    }));
  });

  // ---------------- Session ended ----------------
  static Future<void> showSessionEnded() => _showOnce('sessionEnded', (context) => SessionEndedSheet.show(context));

  /// Signs the user out and returns to the start of the login flow.
  static Future<void> reLogin() async {
    await UzslApi.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setInt('tabIndex', 0);
    navigatorKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LanguageChoose()), (route) => false);
  }

  // ---------------- Update ----------------
  /// Shows the (non-dismissible) update sheet when the installed version is below [minVersion].
  static Future<bool> checkForUpdate({String? minVersion}) async {
    if (minVersion == null) return false; // TODO: fetch the minimum supported version from the backend.
    try {
      final info = await PackageInfo.fromPlatform();
      if (!_isOlder(info.version, minVersion)) return false;
    } catch (_) {
      return false;
    }
    _showOnce('update', (context) => UpdateSheet.show(context, onUpdate: () async {
      try {
        return await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }));
    return true;
  }

  static bool _isOlder(String current, String min) {
    List<int> parts(String v) => v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final a = parts(current), b = parts(min);
    for (int i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }
}

class _SheetObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => AppSheets._lastPushed = route;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => AppSheets._routeGone(route, removed: false);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => AppSheets._routeGone(route, removed: true);
}

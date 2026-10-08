import 'package:connectivity_plus/connectivity_plus.dart';

/// Page loading: keeps the page's skeleton up while the phone is offline (ConnectivityGate shows the
/// no-internet sheet meanwhile) and lets it finish by itself as soon as the connection is back.
class AppLoading {
  AppLoading._();

  /// Shortest time the skeleton stays, so it doesn't just flash on a fast load.
  static const Duration _minimum = Duration(milliseconds: 400);

  static Future<void> ready() => Future.wait([Future.delayed(_minimum), _waitUntilOnline()]);

  static bool _isOffline(List<ConnectivityResult> results) => results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  static Future<void> _waitUntilOnline() async {
    final connectivity = Connectivity();
    if (!_isOffline(await connectivity.checkConnectivity())) return;
    await connectivity.onConnectivityChanged.firstWhere((results) => !_isOffline(results));
  }
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:signlang/services/app_sheets.dart';

/// Watches the network and shows [NoInternetSheet] while the phone is offline;
/// the sheet closes by itself once the connection comes back.
class ConnectivityGate extends StatefulWidget {
  final Widget child;
  const ConnectivityGate({super.key, required this.child});
  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
    AppSheets.onNoInternetRemoved = _retry;
    // The stream only reports changes, so check once at startup too.
    // Wait a frame: this widget sits above the Navigator, which must exist first.
    WidgetsBinding.instance.addPostFrameCallback((_) async => _apply(await _connectivity.checkConnectivity()));
  }

  @override
  void dispose() {
    _sub?.cancel();
    if (AppSheets.onNoInternetRemoved == _retry) AppSheets.onNoInternetRemoved = null;
    super.dispose();
  }

  static bool _isOffline(List<ConnectivityResult> results) => results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  void _apply(List<ConnectivityResult> results) {
    if (!mounted) return;
    if (_isOffline(results)) {
      AppSheets.showNoInternet(onRetry: _retry);
    } else {
      AppSheets.hideNoInternet();
    }
  }

  Future<void> _retry() async => _apply(await _connectivity.checkConnectivity());

  @override
  Widget build(BuildContext context) => widget.child;
}

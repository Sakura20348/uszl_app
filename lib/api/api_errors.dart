import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/app_sheets.dart';
import 'package:signlang/services/theme_service.dart';

/// Shows a failed API call: no internet / server error sheets, or a red snackbar with the reason.
Future<void> showApiError(BuildContext context, ApiException error, {VoidCallback? onRetry}) async {
  if (error.isNetwork) {
    // Couldn't reach the server: only say "no internet" if the phone really has no network.
    // Otherwise the server is down or the app points to the wrong address (API_URL).
    final results = await Connectivity().checkConnectivity();
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (offline) {
      AppSheets.showNoInternet(onRetry: () { AppSheets.hideNoInternet(); onRetry?.call(); });
    } else {
      debugPrint('Server not reachable at ${UzslApi.baseUrl}');
      AppSheets.showServerError(onRetry: onRetry);
    }
    return;
  }
  if (error.status == 503 && error.message.contains('SMS')) {
    // The public server has no SMS provider yet: suggest email instead of a generic server error
    showRedSnackBar(context, AppLocalizations.of(context)!.translate('sms_unavailable'));
    return;
  }
  if (error.status >= 500) {
    AppSheets.showServerError(onRetry: onRetry);
    return;
  }
  if (!context.mounted) return;
  final loc = AppLocalizations.of(context)!;
  final message = switch (error.status) {
    429 => loc.translate('too_many_tries'),
    400 when error.message.contains('expired') => loc.translate('code_expired'),
    400 when error.message.contains('Wrong code') => loc.translate('wrong_code'),
    _ => error.message,
  };
  showRedSnackBar(context, message);
}

/// A plain (not red) message, e.g. "We sent you an email".
void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  );
}

void showRedSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message), backgroundColor: AppPalette.bg(const Color(0xFFD32F2F)), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

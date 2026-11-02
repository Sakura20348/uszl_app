import 'package:flutter/cupertino.dart';
import 'package:signlang/l10n/app_localizations.dart';

// =======================================================================
// Search Words to download
// =======================================================================
class DownloadData {
  final BuildContext context; DownloadData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  late final List<Map<String, dynamic>> downloadItems = [
    { 'key': loc.translate('complete_dictionary'), 'size': '184 MB', 'status': 'pending', 'progress': 0.0, 'image': 'web/icons/book_icon.webp' },
    { 'key': loc.translate('emergency_phrases'), 'size': '24 MB', 'status': 'pending', 'progress': 0.0, 'image': 'web/icons/emergency.webp' },
    { 'key': loc.translate('example_sentences'), 'size': '42 MB', 'status': 'pending', 'progress': 0.0, 'image': 'web/icons/save_icon.webp' },
  ];
}

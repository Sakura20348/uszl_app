import 'package:flutter/material.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/theme_service.dart';

/// Shown in a lesson slide's video box when the video is missing or failed to load.
class LessonVideoUnavailable extends StatelessWidget {
  const LessonVideoUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_outlined, size: 36, color: c.subText),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.translate('video_unavailable'), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: c.subText)),
        ],
      ),
    );
  }
}

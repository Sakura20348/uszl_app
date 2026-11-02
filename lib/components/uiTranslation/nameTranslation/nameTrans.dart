import 'package:flutter/cupertino.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../../uiTextBooks/nameTextbooks/nameTextbooks.dart';

class TransData {
  final BuildContext context; TransData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get itemsData => [
    {
      'id': '0', 'image': 'web/icons/hand.webp', 'titleKey': loc.translate('gesture_text'), 'subKey': loc.translate('gesture_text_sub'), 'learned': LessonProgress.instance.learnedOf('1'),
    },
    {
      'id': '1', 'image': 'web/icons/trans.webp', 'titleKey': loc.translate('text_gesture'), 'subKey': loc.translate('text_gesture_sub'), 'learned': LessonProgress.instance.learnedOf('1'),
    },
    {
      'id': '2', 'image': 'web/icons/voice.webp', 'titleKey': loc.translate('speech_text'), 'subKey': loc.translate('speech_text_sub'), 'learned': LessonProgress.instance.learnedOf('1'),
    },
    {
      'id': '3', 'image': 'web/icons/noise.webp', 'titleKey': loc.translate('text_speech'), 'subKey': loc.translate('text_speech_sub'), 'learned': LessonProgress.instance.learnedOf('1'),
    }
  ];
}
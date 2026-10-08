import 'package:flutter/cupertino.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../../uiTextBooks/nameTextbooks/nameTextbooks.dart';

class TransData {
  final BuildContext context; TransData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get itemsData => [
    {
      'id': '0', 'image': 'web/icons/hand.png', 'titleKey': loc.translate('gesture_text'), 'subKey': loc.translate('gesture_text_sub'), 'learned': LessonProgress.instance.learnedOf('1'),
    },
    {
      'id': '1', 'image': 'web/icons/trans.png', 'titleKey': loc.translate('text_gesture'), 'subKey': loc.translate('text_gesture_sub'), 'learned': LessonProgress.instance.learnedOf('1'),
    },
    {
      'id': '2', 'image': 'web/icons/voice.png', 'titleKey': loc.translate('speech_text'), 'subKey': loc.translate('speech_text_sub'), 'learned': LessonProgress.instance.learnedOf('1'),
    },
    {
      'id': '3', 'image': 'web/icons/noise.png', 'titleKey': loc.translate('text_speech'), 'subKey': loc.translate('text_speech_sub'), 'learned': LessonProgress.instance.learnedOf('1'),
    }
  ];
}
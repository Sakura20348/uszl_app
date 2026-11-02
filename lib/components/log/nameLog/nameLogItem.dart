import 'package:flutter/cupertino.dart';

import '../../../l10n/app_localizations.dart';

class WhyUzslData {
  final BuildContext context; WhyUzslData({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get whyUzslItems => [
    { 'id': '0', 'image': "web/icons/folder.webp", 'test': localizations.translate('folder') },
    { 'id': '1', 'image': "web/icons/education.webp", 'test': localizations.translate('education') },
    { 'id': '2', 'image': "web/icons/hand.webp", 'test': localizations.translate('hand') },
    { 'id': '3', 'image': "web/icons/connecting.webp", 'test': localizations.translate('connecting') },
    { 'id': '4', 'image': "web/icons/curiosity.webp", 'test': localizations.translate('curiosity') },
  ];
  Map<String, List<Map<String, dynamic>>> get storesByWhyUsItem => { '0': whyUzslItems };
}

class FromWhereData {
  final BuildContext context; FromWhereData({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get fromWhereItem => [
    { 'id': '0', 'image': 'web/icons/connecting.webp', 'test': localizations.translate('through_bloggers') },
    { 'id': '1', 'image': 'web/icons/google.webp', 'test': localizations.translate('google') },
    { 'id': '2', 'image': 'web/icons/apple.webp', 'test': localizations.translate('apple_store') },
    { 'id': '3', 'image': 'web/icons/google_play.webp', 'test': localizations.translate('google_play') },
    { 'id': '4', 'image': 'web/icons/youtube.webp', 'test': localizations.translate('youtube') },
    { 'id': '5', 'image': 'web/icons/instagram.webp', 'test': localizations.translate('instagram') },
    { 'id': '6', 'image': 'web/icons/telegram.webp', 'test': localizations.translate('telegram') },
    { 'id': '7', 'image': 'web/icons/curiosity.webp', 'test': localizations.translate('other') }
  ];
  Map<String, List<Map<String, dynamic>>> get storesByFrom => { '0': fromWhereItem };
}

class HowLongData {
  final BuildContext context; HowLongData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get howLongItem => [
    { 'id': '0', 'image': 'web/icons/time_day.webp', 'test': "5 ${loc.translate('day')}", 'title': loc.translate('day_sub_1') },
    { 'id': '1', 'image': 'web/icons/time_day.webp', 'test': "10 ${loc.translate('day')}", 'title': loc.translate('day_sub_2') },
    { 'id': '2', 'image': 'web/icons/time_day.webp', 'test': "15 ${loc.translate('day')}", 'title': loc.translate('day_sub_3') },
    { 'id': '3', 'image': 'web/icons/time_day.webp', 'test': "20 ${loc.translate('day')}", 'title': loc.translate('day_sub_4') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeByHowLong => { '0': howLongItem };
}

class QuizOptionsData {
  final BuildContext context; QuizOptionsData({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get quizOptionsItem => [
    { 'image': 'web/sign_lang_image/five.webp', 'label': localizations.translate('five') }, { 'image': 'web/sign_lang_image/one.webp', 'label': localizations.translate('one') },
    { 'image': 'web/sign_lang_image/three.webp', 'label': localizations.translate('three') }, { 'image': 'web/sign_lang_image/two.webp', 'label': localizations.translate('two') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeQuizOptions => { '0': quizOptionsItem };
}

class GreatData {
  final BuildContext context; GreatData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get greatItem => [
    { 'id': '0', 'image': 'web/icons/hand.webp', 'title': loc.translate('gestures'), 'titleSub': "8 ${loc.translate('pieces')}" },
    { 'id': '1', 'image': 'web/icons/lightning.webp', 'title': loc.translate('points'), 'titleSub': '30' }, { 'id': '2', 'image': 'web/icons/star.webp', 'title': loc.translate('result'), 'titleSub': '75%' }
  ];
  Map<String, List<Map<String, dynamic>>> get storeGreatItem => { '0': greatItem };
}

class SetUpData {
  final BuildContext context; SetUpData({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get setUpItem => [
    { 'id': '0', 'title': localizations.translate('set_up_1') }, { 'id': '1', 'title': localizations.translate('set_up_2') },
    { 'id': '2', 'title': localizations.translate('set_up_3') }, { 'id': '3', 'title': localizations.translate('set_up_4') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeSetUpItem => { '0': setUpItem };
}
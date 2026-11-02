import 'package:flutter/material.dart';
import 'package:signlang/services/achievement_service.dart';

import '../../../l10n/app_localizations.dart';

class AchievementsData {
  final BuildContext context;
  AchievementsData({required this.context});
  AppLocalizations get localizations => AppLocalizations.of(context)!;

  /// Ids opened by the last [init] call, to announce them.
  List<String> justUnlocked = [];

  Future<void> init() async { justUnlocked = await AchievementService.instance.refresh(); }

  List<Map<String, dynamic>> get achievementsItems => [
    for (final a in AchievementService.all)
      {
        'id': a.id, 'image': a.image, 'titleKey': localizations.translate(a.titleKey),
        'subKey': localizations.translate(a.taskKey), 'subTitleKey': localizations.translate(a.doneKey),
        'unlocked': AchievementService.instance.isUnlocked(a.id), 'isNew': AchievementService.instance.isNew(a.id),
        'progress': AchievementService.instance.progressOf(a), 'target': a.target,
      },
  ];
  Map<String, List<Map<String, dynamic>>> get storesByAchievementsItems => { '0': achievementsItems, };
}

class AllSettingsData {
  final BuildContext context;
  AllSettingsData({ required this.context });
  AppLocalizations get localizations => AppLocalizations.of(context)!;

  String get _currentLanguageFlag {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en': return 'web/images/eng_flag.webp';
      case 'ru': return 'web/images/rus_flag.webp';
      default:   return 'web/images/uzbek_flag.webp';
    }
  }

  String get _currentLanguageName {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en': return 'English';
      case 'ru': return 'Русский';
      default:   return 'Uzbek';
    }
  }

  List<Map<String, dynamic>> get allSettingsItem => [
    { 'id': '0', 'image': 'web/icons/user.webp', 'titleKey': localizations.translate('personal_information') },
    { 'id': '1', 'image': 'web/icons/chart_bar_big_columns.webp', 'titleKey': localizations.translate('development_details') },
    { 'id': '2', 'image': 'web/icons/translate.webp', 'titleKey': localizations.translate('application_language'), 'lang': _currentLanguageFlag, 'name': _currentLanguageName },
    { 'id': '8', 'icon': Icons.palette_rounded, 'titleKey': localizations.translate('season_colors') },
    { 'id': '3', 'image': 'web/icons/bell.webp', 'titleKey': localizations.translate('notifications') },
    { 'id': '4', 'image': 'web/icons/bookmark.webp', 'titleKey': localizations.translate('saved') },
    { 'id': '5', 'image': 'web/icons/server.webp', 'titleKey': localizations.translate('contribute') },
    { 'id': '6', 'image': 'web/icons/message_circle_question_mark.webp', 'titleKey': localizations.translate('help') },
    { 'id': '7', 'image': 'web/icons/info_yellow.webp', 'titleKey': localizations.translate('about_the_application') },
  ];
  Map<String, List<Map<String, dynamic>>> get storesByAllSettings => { '0': allSettingsItem };
}

class AllProfileData {
  // Data for profile items
  final BuildContext context;
  final String name;
  final String phone;
  final bool isAppleConnected;
  final bool isGoogleConnected;

  AllProfileData({
    required this.context,
    this.name = '',
    this.phone = '',
    this.isAppleConnected = false,
    this.isGoogleConnected = false,
  });
  AppLocalizations get loc => AppLocalizations.of(context)!;

  List<Map<String, dynamic>> get allProfileItems {
    String linkSubKey = '';
    if (isAppleConnected && isGoogleConnected) { linkSubKey = 'Google・Apple'; }
    else if (isAppleConnected) { linkSubKey = 'Apple'; }
    else if (isGoogleConnected) { linkSubKey = 'Google'; }
    else { linkSubKey = loc.translate('disconnected'); }

    return [
      { 'id': '0', 'image': 'web/icons/user.webp', 'titleKey': loc.translate('name'), 'subKey': name },
      { 'id': '1', 'image': 'web/icons/phone.webp', 'titleKey': loc.translate('phone_number'), 'subKey': phone },
      { 'id': '2', 'image': 'web/icons/link.webp', 'titleKey': loc.translate('connect_account'), 'subKey': linkSubKey }
    ];
  }
}

class NotificationProfileData {
  final BuildContext context;
  NotificationProfileData({required this.context});
  AppLocalizations get loc => AppLocalizations.of(context)!;

  List<Map<String, dynamic>> get notificationProfileItems => [
    { 'id': '0', 'image': 'web/icons/bell.webp', 'titleKey': loc.translate('general_notifications') },
    { 'id': '1', 'image': 'web/icons/refresh_ccw_dot.webp', 'titleKey': loc.translate('daily_reminders') },
    { 'id': '2', 'image': 'web/icons/bullseye.webp', 'titleKey': loc.translate('goal_reminders') },
    { 'id': '3', 'image': 'web/icons/trophy.webp', 'titleKey': loc.translate('new_achievements') },
    { 'id': '4', 'image': 'web/icons/news.webp', 'titleKey': loc.translate('news_content') },
    { 'id': '5', 'image': 'web/icons/chart_bubble.webp', 'titleKey': loc.translate('activity_notes') }
  ];
}

class AboutData {
  final BuildContext context;
  AboutData({required this.context});
  AppLocalizations get loc => AppLocalizations.of(context)!;

  List<Map<String, dynamic>> get aboutItems => [
    {
      'id': '0',
      'image': 'web/icons/globe_alt.webp',
      'titleKey': loc.translate('official_website'),
      'subKey': loc.translate('official_website_sub')
    },
    {
      'id': '1',
      'image': 'web/icons/star_half.webp',
      'titleKey': loc.translate('app_rating'),
      'subKey': loc.translate('app_rating_sub')
    },
    {
      'id': '2',
      'image': 'web/icons/share.webp',
      'titleKey': loc.translate('share_with_friends'),
      'subKey': loc.translate('share_with_friends_sub')
    },
    {
      'id': '3',
      'image': 'web/icons/file_detail.webp',
      'titleKey': loc.translate('legal_information'),
      'subKey': loc.translate('legal_information_sub')
    },
  ];
}

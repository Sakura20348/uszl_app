import 'package:flutter/cupertino.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks2.dart';
import 'package:signlang/services/lesson_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/services/achievement_service.dart';
import 'package:signlang/services/statistics_service.dart';

import '../../../l10n/app_localizations.dart';

// =======================================================================
// Lesson Progress
// =======================================================================
class LessonProgress {
  static const int maxImolar = 19;

  LessonProgress._();
  static final LessonProgress instance = LessonProgress._();
  final Map<String, int> _learned = {};
  final Set<String> _completed = {};
  SharedPreferences? _prefs;
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final completedList = _prefs!.getStringList('lp_completed') ?? [];
    _completed.addAll(completedList);
    final learnedList = _prefs!.getStringList('lp_learned') ?? [];
    for (final entry in learnedList) { final parts = entry.split(':'); if (parts.length == 2) { _learned[parts[0]] = int.tryParse(parts[1]) ?? 0; } }
  }

  int learnedOf(String id) => _learned[id] ?? 0;
  void setLearned(String id, int value) { _learned[id] = value; _saveLearned(); }

  bool isCompleted(String id) => _completed.contains(id);
  /// How many textbook lessons have been finished (unlocks Translation after the first one).
  int get completedCount => _completed.length;
  void markCompleted(String id) {
    AchievementService.instance.recordLessonFinished(perfect: mistakes == 0 && imolar > 0);
    // Send this play's result to the server once (markCompleted runs on the exam and again on "lessons over")
    if (!_resultSent) {
      _resultSent = true;
      final seconds = _startedAt == null ? 0 : DateTime.now().difference(_startedAt!).inSeconds.clamp(0, 4 * 60 * 60);
      LessonSync.report(id, correct: ballar ~/ 5, wrong: mistakes, durationSeconds: seconds);
    }
    if (!_completed.contains(id)) { _completed.add(id); _prefs?.setStringList('lp_completed', _completed.toList()); _incrementLessonsToday(); } }
  /// A lesson played from the server (BuiltinLessonPlayer): the server already has the result,
  /// so it is only marked here, without sending it again.
  void markCompletedOnServer(String id) {
    if (!_completed.contains(id)) { _completed.add(id); _prefs?.setStringList('lp_completed', _completed.toList()); _incrementLessonsToday(); }
  }
  void _incrementLessonsToday() { StatisticsService.instance.syncPeriods(); int current = _prefs?.getInt('stat_lessons_today') ?? 0; _prefs?.setInt('stat_lessons_today', current + 1); }
  void _saveLearned() { final list = _learned.entries.map((e) => '${e.key}:${e.value}').toList(); _prefs?.setStringList('lp_learned', list); }

  int imolar = 0; int ballar = 0; int mistakes = 0;
  // When this play of the lesson started, and whether its result went to the server
  DateTime? _startedAt; bool _resultSent = false;

  void addCorrect() { imolar = (imolar + 1).clamp(0, maxImolar); ballar = ballar + 5; StatisticsService.instance.addPoints(5); }
  void addWrong() { imolar = (imolar - 1).clamp(0, maxImolar); mistakes++; }
  /// Learned counts of all five textbooks, from the completed lessons. Every textbook's "lessons over"
  /// screen calls this (they used to all update the Alphabet card).
  void recomputeLearned(BuildContext context) {
    int sumOf(List<Map<String, dynamic>> items) =>
        items.where((i) => isCompleted('${i['id']}')).fold(0, (sum, i) => sum + (int.tryParse('${i['count']}') ?? 0));
    _learned['0'] = sumOf(AlphabetLessonsData(context: context).alphabetLessonsItem);
    _learned['1'] = sumOf(NumbersLessonsData(context: context).numLessonsItem);
    _learned['2'] = sumOf(FamilyLessonsData(context: context).famLessonsItem);
    _learned['3'] = sumOf(FoodLessonsData(context: context).item);
    _learned['4'] = sumOf(FeelingsLessonsData(context: context).item);
    _saveLearned();
  }

  /// Adds lessons the account completed on the server (e.g. on another phone).
  void restoreCompleted(Iterable<String> ids) {
    _completed.addAll(ids);
    _prefs?.setStringList('lp_completed', _completed.toList());
  }

  /// Forgets this phone's progress (another account logged in, or log out).
  void clearLocal() { _completed.clear(); _learned.clear(); resetStats(); }

  void resetStats() { imolar = 0; ballar = 0; mistakes = 0; _startedAt = DateTime.now(); _resultSent = false; }
}

// =======================================================================
// Lessons Textbooks data
// =======================================================================
class LessonsTextbooksData {
  final BuildContext context; LessonsTextbooksData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get lessonsTextbooksItems => [
    {
      'id': '0', 'image': 'web/images/book_3d.png', 'imageWidth': 115.0, 'imageRight': -10, 'titleKey': loc.translate('alphabet'), 'subKey': loc.translate('alphabet_sub'),
      'letter': loc.translate('letter_learned'), 'learned': LessonProgress.instance.learnedOf('0'), 'total': 28
    },
    {
      'id': '1', 'image': 'web/images/number_image.png', 'imageWidth': 115.0, 'imageRight': -15, 'titleKey': loc.translate('numbers'), 'subKey': '+ ${loc.translate('numbers')}',
      'letter': loc.translate('numbers_sub'), 'learned': LessonProgress.instance.learnedOf('1'), 'total': 48
    },
    {
      'id': '2', 'image': 'web/images/family.png', 'imageWidth': 115.0, 'imageRight': -20, 'titleKey': loc.translate('family'), 'subKey': loc.translate('words'),
      'letter': loc.translate('words_learn'), 'learned': LessonProgress.instance.learnedOf('2'), 'total': 67
    },
    {
      'id': '3', 'image': 'web/images/food.png', 'imageWidth': 115.0, 'imageRight': -20, 'titleKey': loc.translate('food'), 'subKey': loc.translate('food_sub'),
      'letter': loc.translate('words_learn'), 'learned': LessonProgress.instance.learnedOf('3'), 'total': 85
    },
    {
      'id': '4', 'image': 'web/images/feelings.png', 'imageWidth': 115.0, 'titleKey': loc.translate('feelings'), 'subKey': loc.translate('feelings_sub'),
      'letter': loc.translate('words_learn'), 'learned': LessonProgress.instance.learnedOf('4'), 'total': 24
    },
    {
      'id': '5', 'image': 'web/images/daily_life.png', 'imageWidth': 115.0, 'titleKey': loc.translate('daily_life'), 'subKey': loc.translate('daily_life_sub'),
      'letter': loc.translate('words_learn'), 'learned': LessonProgress.instance.learnedOf('5'), 'total': 32
    },
    {
      'id': '6', 'image': 'web/images/med.png', 'imageWidth': 150.0, 'imageRight': -40, 'imageBottom': 1, 'titleKey': loc.translate('medicine'), 'subKey': loc.translate('daily_life_sub'),
      'letter': loc.translate('words_learn'), 'learned': LessonProgress.instance.learnedOf('6'), 'total': 18
    },
    {
      'id': '7', 'image': 'web/images/bus.png', 'imageWidth': 150.0, 'imageRight': -40, 'imageBottom': 0, 'titleKey': loc.translate('transportation'), 'subKey': loc.translate('transportation_sub'),
      'letter': loc.translate('words_learn'), 'learned': LessonProgress.instance.learnedOf('7'), 'total': 23
    },
    {
      'id': '8', 'image': 'web/images/public_services.png', 'imageWidth': 150.0, 'imageRight': -40, 'imageBottom': 0, 'titleKey': loc.translate('public_services'), 'subKey': loc.translate('public_services_sub'),
      'letter': loc.translate('words_learn'), 'learned': LessonProgress.instance.learnedOf('8'), 'total': 32
    },
    {
      'id': '9', 'image': 'web/images/sports.png', 'imageWidth': 150.0, 'imageRight': -40, 'imageBottom': 0, 'titleKey': loc.translate('sports'), 'subKey': loc.translate('sports_sub'),
      'letter': loc.translate('words_learn'), 'learned': LessonProgress.instance.learnedOf('9'), 'total': 18
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storesByLessonsTextbooks => { '0': lessonsTextbooksItems, };
}

class OneLessonsGreatData {
  final BuildContext context; OneLessonsGreatData({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get oneLessonsGreatItem => [
    { 'id': '0', 'image': 'web/icons/hand.png', 'title': localizations.translate('gestures') }, { 'id': '1', 'image': 'web/icons/lightning.png', 'title': localizations.translate('points') },
    { 'id': '2', 'image': 'web/icons/star.png', 'title': localizations.translate('result') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeOneLessonsGreatItem => { '0': oneLessonsGreatItem };
}

// =======================================================================
// ALPHABET LESSONS
// =======================================================================
class AlphabetLessonsData {
  final BuildContext context; AlphabetLessonsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get alphabetLessonsItem => [
    {
      'id': 'alp_0', 'count': 4, 'image': '', // video A-E
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': 'A - E ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '4 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_1', 'count': 4, 'image': '', // video F-I
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': 'F - I ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_2', 'count': 4, 'image': '', // video J-M
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': 'J - M ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_3', 'count': 4, 'image': '', // video N-Q
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': 'N - Q ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_4', 'count': 4, 'image': '', // video R-U
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': 'R - U ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_5', 'count': 4, 'image': '', // video V-Z
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': 'V - Z ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_6', 'count': 4, 'image': '', // video O`-Ch
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': 'O` - NG ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storesByAlphabetLessons => { '0': alphabetLessonsItem };
}

// =======================================================================
// F AND I LESSONS
// =======================================================================
class LevelFData {
  final BuildContext context; LevelFData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelFItem => [
    {
      'image': '', // level d
      'label': loc.translate('level_d')
    },
    { 'image': 'web/sign_lang_image/level_f.png', 'label': loc.translate('level_f') },
    { 'image': 'web/sign_lang_image/level_a.png', 'label': loc.translate('level_a') },
    {
      'image': '', // level e
      'label': loc.translate('level_e')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelF => { '0': levelFItem };
}

class LevelGData {
  final BuildContext context; LevelGData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelGItem => [
    { 'image': 'web/sign_lang_image/level_f.png', 'label': loc.translate('level_f') }, { 'image': 'web/sign_lang_image/level_a.png', 'label': loc.translate('level_a') },
    { 'image': 'web/sign_lang_image/level_b.png', 'label': loc.translate('level_b') },
    {
      'image': '', // level g
      'label': loc.translate('level_g')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelG => { '0': levelGItem };
}

class LevelHData {
  final BuildContext context; LevelHData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelHItem => [
    { 'image': 'web/sign_lang_image/level_h.png', 'label': loc.translate('level_h') },
    {
      'image': '', // level e
      'label': loc.translate('level_e')
    },
    {
      'image': '', // level d
      'label': loc.translate('level_d')
    },
    {
      'image': '', // level g
      'label': loc.translate('level_g')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelH => { '0': levelHItem };
}

class LevelIData {
  final BuildContext context; LevelIData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelIItem => [
    { 'image': 'web/sign_lang_image/level_a.png', 'label': loc.translate('level_a') },
    {
      'image': '', // level g
      'label': loc.translate('level_g')
    },
    {
      'image': '', // level i
      'label': loc.translate('level_i')
    },
    {
      'image': '', // level d
      'label': loc.translate('level_d')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelI => { '0': levelIItem };
}

class Level2Choose1Data {
  final BuildContext context; Level2Choose1Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level2Choose1Items => [
    {
      'id': '0',
      'image': '' // level e
    },
    { 'id': '1', 'image': 'web/sign_lang_image/level_a.png' },
    {
      'id': '2',
      'image': '' // level d
    },
    { 'id': '3', 'image': 'web/sign_lang_image/level_f.png' },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel2Choose1 => { '0': level2Choose1Items };
}

class Level2Choose2Data {
  final BuildContext context; Level2Choose2Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level2Choose2Items => [
    {
      'id': '0',
      'image': '' // level i
    },
    { 'id': '1', 'image': 'web/sign_lang_image/level_b.png' },
    { 'id': '2', 'image': 'web/sign_lang_image/level_h.png' },
    {
      'id': '3',
      'image': '' // level g
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel2Choose2 => { '0': level2Choose2Items };
}

// =======================================================================
// J AND M LESSONS
// =======================================================================
class LevelJData {
  final BuildContext context; LevelJData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelJItem => [
    {
      'image': '', // level e
      'label': loc.translate('level_e')
    },
    { 'image': 'web/sign_lang_image/level_h.png', 'label': loc.translate('level_h') },
    { 'image': 'web/sign_lang_image/level_b.png', 'label': loc.translate('level_b') },
    {
      'image': '', // level j
      'label': loc.translate('level_j')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelJ => { '0': levelJItem };
}

class LevelKData {
  final BuildContext context; LevelKData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelKItem => [
    {
      'image': '', // level j
      'label': loc.translate('level_d')
    },
    {
      'image': '', // level i
      'label': loc.translate('level_i')
    },
    {
      'image': '', // level k
      'label': loc.translate('level_k')
    },
    {
      'image': '', // level g
      'label': loc.translate('level_g')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelK => { '0': levelKItem };
}

class LevelLData {
  final BuildContext context; LevelLData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelLItem => [
    {
      'image': '', // level l
      'label': loc.translate('level_l')
    },
    {
      'image': '', // level d
      'label': loc.translate('level_d')
    },
    { 'image': 'web/sign_lang_image/level_b.png', 'label': loc.translate('level_b') }, { 'image': 'web/sign_lang_image/level_h.png', 'label': loc.translate('level_h') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelL => { '0': levelLItem };
}

class LevelMData {
  final BuildContext context; LevelMData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelMItem => [
    {
      'image': '', // level k
      'label': loc.translate('level_k')
    },
    { 'image': 'web/sign_lang_image/level_a.png', 'label': loc.translate('level_a') },
    {
      'image': '', // level i
      'label': loc.translate('level_i')
    },
    {
      'image': '', // level m
      'label': loc.translate('level_m')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelM => { '0': levelMItem };
}

class Level3Choose1Data {
  final BuildContext context; Level3Choose1Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level3Choose1Items => [
    {
      'id': '0',
      'image': '' // level m
    },
    { 'id': '1', 'image': 'web/sign_lang_image/level_f.png' },
    {
      'id': '2',
      'image': '' // level l
    },
    {
      'id': '3',
      'image': '' // level g
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel3Choose1 => { '0': level3Choose1Items };
}

class Level3Choose2Data {
  final BuildContext context; Level3Choose2Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level3Choose2Items => [
    {
      'id': '0',
      'image': '' // level k
    },
    { 'id': '1', 'image': 'web/sign_lang_image/level_h.png' },
    {
      'id': '2',
      'image': '' // level l
    },
    { 'id': '3', 'image': 'web/sign_lang_image/level_f.png' },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel3Choose2 => { '0': level3Choose2Items };
}

// =======================================================================
// N AND Q LESSONS
// =======================================================================
class LevelNData {
  final BuildContext context; LevelNData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelNItem => [
    {
      'image': '', // level e
      'label': loc.translate('level_e')
    },
    {
      'image': '', // level d
      'label': loc.translate('level_d')
    },
    {
      'image': '', // level n
      'label': loc.translate('level_n')
    },
    { 'image': 'web/sign_lang_image/level_a.png', 'label': loc.translate('level_a') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelN => { '0': levelNItem };
}

class LevelOData {
  final BuildContext context; LevelOData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelOItem => [
    {
      'image': '', // level e
      'label': loc.translate('level_e')
    },
    {
      'image': '', // level k
      'label': loc.translate('level_k')
    },
    {
      'image': '', // level j
      'label': loc.translate('level_j')
    },
    {
      'image': '', // level o
      'label': loc.translate('level_o')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelO => { '0': levelOItem };
}

class LevelPData {
  final BuildContext context; LevelPData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelPItem => [
    {
      'image': '', // level p
      'label': loc.translate('level_p')
    },
    {
      'image': '', // level k
      'label': loc.translate('level_k')
    },
    { 'image': 'web/sign_lang_image/level_f.png', 'label': loc.translate('level_f') }, { 'image': 'web/sign_lang_image/level_h.png', 'label': loc.translate('level_h') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelP => { '0': levelPItem };
}

class LevelQData {
  final BuildContext context; LevelQData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelQItem => [
    {
      'image': '', // level l
      'label': loc.translate('level_l')
    },
    {
      'image': '', // level q
      'label': loc.translate('level_q')
    },
    { 'image': 'web/sign_lang_image/level_b.png', 'label': loc.translate('level_b') },
    {
      'image': '', // level m
      'label': loc.translate('level_m')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelQ => { '0': levelQItem };
}

class Level4Choose1Data {
  final BuildContext context; Level4Choose1Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level4Choose1Items => [
    {
      'id': '0',
      'image': '' // level n
    },
    { 'id': '1', 'image': 'web/sign_lang_image/level_a.png' },
    {
      'id': '2',
      'image': '' // level o
    },
    {
      'id': '3',
      'image': '' // level m
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel4Choose1 => { '0': level4Choose1Items };
}

class Level4Choose2Data {
  final BuildContext context; Level4Choose2Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level4Choose2Items => [
    {
      'id': '0',
      'image': '' // level k
    },
    { 'id': '1', 'image': 'web/sign_lang_image/level_h.png' },
    {
      'id': '2',
      'image': '' // level p
    },
    {
      'id': '3',
      'image': '' // level o
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel4Choose2 => { '0': level4Choose2Items };
}

// =======================================================================
// R AND U LESSONS
// =======================================================================
class LevelRData {
  final BuildContext context; LevelRData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelRItem => [
    {
      'image': '', // level k
      'label': loc.translate('level_k')
    },
    {
      'image': '', // level d
      'label': loc.translate('level_d')
    },
    {
      'image': '', // level q
      'label': loc.translate('level_q')
    },
    {
      'image': '', // level r
      'label': loc.translate('level_r')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelR => { '0': levelRItem };
}

class LevelSData {
  final BuildContext context; LevelSData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelSItem => [
    { 'image': 'web/sign_lang_image/level_h.png', 'label': loc.translate('level_h') },
    {
      'image': '', // level s
      'label': loc.translate('level_s')
    },
    {
      'image': '', // level l
      'label': loc.translate('level_l')
    },
    { 'image': 'web/sign_lang_image/level_a.png', 'label': loc.translate('level_a') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelS => { '0': levelSItem };
}

class LevelTData {
  final BuildContext context; LevelTData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelTItem => [
    {
      'image': '', // level j
      'label': loc.translate('level_j')
    },
    { 'image': 'web/sign_lang_image/level_a.png', 'label': loc.translate('level_a') },
    {
      'image': '', // level k
      'label': loc.translate('level_k')
    },
    {
      'image': '', // level t
      'label': loc.translate('level_t')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelT => { '0': levelTItem };
}

class LevelUData {
  final BuildContext context; LevelUData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelUItem => [
    {
      'image': '', // level u
      'label': loc.translate('level_u')
    },
    { 'image': 'web/sign_lang_image/level_a.png', 'label': loc.translate('level_a') },
    {
      'image': '', // level k
      'label': loc.translate('level_k')
    },
    {
      'image': '', // level t
      'label': loc.translate('level_t')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelU => { '0': levelUItem };
}

class Level5Choose1Data {
  final BuildContext context; Level5Choose1Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level5Choose1Items => [
    {
      'id': '0',
      'image': '' // level g
    },
    { 'id': '1', 'image': 'web/sign_lang_image/level_f.png' },
    {
      'id': '2',
      'image': '' // level u
    },
    {
      'id': '3',
      'image': '' // level t
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel5Choose1 => { '0': level5Choose1Items };
}

class Level5Choose2Data {
  final BuildContext context; Level5Choose2Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level5Choose2Items => [
    {
      'id': '0',
      'image': '' // level r
    },
    {
      'id': '1',
      'image': '' // level u
    },
    {
      'id': '2',
      'image': '' // level s
    },
    { 'id': '3', 'image': 'web/sign_lang_image/level_a.png' },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel5Choose2 => { '0': level5Choose2Items };
}

class Level5Choose3Data {
  final BuildContext context; Level5Choose3Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level5Choose3Items => [
    { 'id': '0', 'image': 'web/sign_lang_image/level_h.png' },
    {
      'id': '1',
      'image': '' // level t
    },
    {
      'id': '2',
      'image': '' // level s
    },
    { 'id': '3', 'image': 'web/sign_lang_image/level_b.png' },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel5Choose3 => { '0': level5Choose3Items };
}

// =======================================================================
// V AND Z LESSONS
// =======================================================================
class LevelVData {
  final BuildContext context; LevelVData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelVItem => [
    {
      'image': '', // level m
      'label': loc.translate('level_m')
    },
    {
      'image': '', // level l
      'label': loc.translate('level_l')
    },
    {
      'image': '', // level g
      'label': loc.translate('level_g')
    },
    {
      'image': '', // level v
      'label': loc.translate('level_v')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelV => { '0': levelVItem };
}

class LevelXData {
  final BuildContext context; LevelXData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelXItem => [
    {
      'image': '', // level p
      'label': loc.translate('level_p')
    },
    {
      'image': '', // level x
      'label': loc.translate('level_x')
    },
    {
      'image': '', // level s
      'label': loc.translate('level_s')
    },
    { 'image': 'web/sign_lang_image/level_a.png', 'label': loc.translate('level_a') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelX => { '0': levelXItem };
}

class LevelYData {
  final BuildContext context; LevelYData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelYItem => [
    {
      'image': '', // level y
      'label': loc.translate('level_y')
    },
    { 'image': 'web/sign_lang_image/level_f.png', 'label': loc.translate('level_f') },
    {
      'image': '', // level q
      'label': loc.translate('level_q')
    },
    {
      'image': '', // level k
      'label': loc.translate('level_k')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelY => { '0': levelYItem };
}

class LevelZData {
  final BuildContext context; LevelZData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelZItem => [
    {
      'image': '', // level p
      'label': loc.translate('level_p')
    },
    {
      'image': '', // level s
      'label': loc.translate('level_s')
    },
    { 'image': 'web/sign_lang_image/level_h.png', 'label': loc.translate('level_h') },
    {
      'image': '', // level z
      'label': loc.translate('level_z')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelZ => { '0': levelZItem };
}

class Level6Choose1Data {
  final BuildContext context; Level6Choose1Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level6Choose1Items => [
    {
      'id': '0',
      'image': '' // level j
    },
    {
      'id': '1',
      'image': '' // level o
    },
    {
      'id': '2',
      'image': '' // level y
    },
    {
      'id': '3',
      'image': '' // level m
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel6Choose1 => { '0': level6Choose1Items };
}

class Level6Choose2Data {
  final BuildContext context; Level6Choose2Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level6Choose2Items => [
    {
      'id': '0',
      'image': '' // level v
    },
    {
      'id': '1',
      'image': '' // level q
    },
    {
      'id': '2',
      'image': '' // level s
    },
    {
      'id': '3',
      'image': '' // level g
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel6Choose2 => { '0': level6Choose2Items };
}

// =======================================================================
// O` AND Ch LESSONS
// =======================================================================
class LevelO2Data {
  final BuildContext context; LevelO2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelO2Item => [
    {
      'image': '', // level p
      'label': loc.translate('level_p')
    },
    {
      'image': '', // level t
      'label': loc.translate('level_t')
    },
    {
      'image': '', // level z
      'label': loc.translate('level_z')
    },
    {
      'image': '', // level o`
      'label': loc.translate('level_o`')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelO2 => { '0': levelO2Item };
}

class LevelG2Data {
  final BuildContext context; LevelG2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelG2Item => [
    {
      'image': '', // level j
      'label': loc.translate('level_j')
    },
    {
      'image': '', // level l
      'label': loc.translate('level_l')
    },
    {
      'image': '', // level x
      'label': loc.translate('level_x')
    },
    {
      'image': '', // level g`
      'label': loc.translate('level_g`')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelG2 => { '0': levelG2Item };
}

class LevelShData {
  final BuildContext context; LevelShData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelShItem => [
    {
      'image': '', // level g`
      'label': loc.translate('level_s')
    },
    {
      'image': '', // level l
      'label': loc.translate('level_g`')
    },
    {
      'image': '', // level x
      'label': loc.translate('level_v')
    },
    {
      'image': '', // level sh
      'label': loc.translate('level_sh')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelSh => { '0': levelShItem };
}

class LevelChData {
  final BuildContext context; LevelChData({required this.context});AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get levelChItem => [
    {
      'image': '', // level n
      'label': loc.translate('level_n')
    },
    {
      'image': '', // level p
      'label': loc.translate('level_p')
    },
    {
      'image': '', // level ch
      'label': loc.translate('level_ch')
    },
    {
      'image': '', // level o
      'label': loc.translate('level_o')
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevelCh => { '0': levelChItem };
}

class Level7Choose1Data {
  final BuildContext context; Level7Choose1Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level7Choose1Items => [
    { 'id': '0', 'image': 'web/sign_lang_image/level_h.png' },
    {
      'id': '1',
      'image': '' // level g`
    },
    {
      'id': '2',
      'image': '' // level ch
    },
    {
      'id': '3',
      'image': '' // level o
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel7Choose1 => { '0': level7Choose1Items };
}

class Level7Choose2Data {
  final BuildContext context; Level7Choose2Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level7Choose2Items => [
    {
      'id': '0', 
      'image': '' // level o
    },
    {
      'id': '1',
      'image': '' // level v
    },
    {
      'id': '2',
      'image': '' // level o`
    },
    {
      'id': '3',
      'image': '' // level sh
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel7Choose2 => { '0': level7Choose2Items };
}

class Level7Choose3Data {
  final BuildContext context; Level7Choose3Data({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get level7Choose3Items => [
    {
      'id': '0',
      'image': '' // level j
    },
    {
      'id': '1',
      'image': '' // level o`
    },
    {
      'id': '2',
      'image': '' // level t
    },
    {
      'id': '3',
      'image': '' // level g
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storeLevel7Choose3 => { '0': level7Choose3Items };
}

// =======================================================================
// NUMBERS LESSONS
// =======================================================================
class NumbersLessonsData {
  final BuildContext context; NumbersLessonsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get numLessonsItem => [
    {
      'id': 'num_0', 'count': 10, 'image': '', // video 0 - 9
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '0 - 9 ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'num_1', 'count': 10, 'image': '', // video 10 - 19
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '10 - 19 ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'num_2', 'count': 10, 'image': '', // video 20 - number
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '20 - ${loc.translate('number')} ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'num_3', 'count': 10, 'image': '', // video 200 - thousand
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '200 - ${loc.translate('thousand')} ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'num_4', 'count': 8, 'image': '', // video 2000 - third
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 'titleKey': '2000 - ${loc.translate('third')} ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storesByNumLessons => { '0': numLessonsItem };
}

class ZeroAndNineData {
  final BuildContext context; ZeroAndNineData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/0.mp4',
      'title': loc.translate('number_zero_symbol'), 'title_sub': loc.translate('number_zero_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/1.mp4',
      'title': loc.translate('number_1_symbol'), 'title_sub': loc.translate('number_1_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/2.mp4',
      'title': loc.translate('number_2_symbol'), 'title_sub': loc.translate('number_2_symbol_sub'),
    },
    {
      'id': '3', 'video': 'assets/videos/numbers_fixed/3.mp4',
      'title': loc.translate('number_3_symbol'), 'title_sub': loc.translate('number_3_symbol_sub'),
    },
    {
      'id': '4', 'video': 'assets/videos/numbers_fixed/4.mp4',
      'title': loc.translate('number_4_symbol'), 'title_sub': loc.translate('number_4_symbol_sub'),
    },
  ];
}

class ZeroAndNine2Data {
  final BuildContext context; ZeroAndNine2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/5.mp4',
      'title': loc.translate('number_5_symbol'), 'title_sub': loc.translate('number_5_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/6.mp4',
      'title': loc.translate('number_6_symbol'), 'title_sub': loc.translate('number_6_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/7.mp4',
      'title': loc.translate('number_7_symbol'), 'title_sub': loc.translate('number_7_symbol_sub'),
    },
    {
      'id': '3', 'video': 'assets/videos/numbers_fixed/8.mp4',
      'title': loc.translate('number_8_symbol'), 'title_sub': loc.translate('number_8_symbol_sub'),
    },
    {
      'id': '4', 'video': 'assets/videos/numbers_fixed/9.mp4',
      'title': loc.translate('number_9_symbol'), 'title_sub': loc.translate('number_9_symbol_sub'),
    },
  ];
}

class TenAndNineteenData {
  final BuildContext context; TenAndNineteenData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/10.mp4',
      'title': loc.translate('number_10_symbol'), 'title_sub': loc.translate('number_10_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/11.mp4',
      'title': loc.translate('number_11_symbol'), 'title_sub': loc.translate('number_11_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/12.mp4',
      'title': loc.translate('number_12_symbol'), 'title_sub': loc.translate('number_12_symbol_sub'),
    },
    {
      'id': '3', 'video': 'assets/videos/numbers_fixed/13.mp4',
      'title': loc.translate('number_13_symbol'), 'title_sub': loc.translate('number_13_symbol_sub'),
    },
    {
      'id': '4', 'video': 'assets/videos/numbers_fixed/14.mp4',
      'title': loc.translate('number_14_symbol'), 'title_sub': loc.translate('number_14_symbol_sub'),
    },
  ];
}

class TenAndNineteen2Data {
  final BuildContext context;
  TenAndNineteen2Data({required this.context});
  AppLocalizations get loc => AppLocalizations.of(context)!;

  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/15.mp4',
      'title': loc.translate('number_15_symbol'), 'title_sub': loc.translate('number_15_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/16.mp4',
      'title': loc.translate('number_16_symbol'), 'title_sub': loc.translate('number_16_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/17.mp4',
      'title': loc.translate('number_17_symbol'), 'title_sub': loc.translate('number_17_symbol_sub'),
    },
    {
      'id': '3', 'video': 'assets/videos/numbers_fixed/18.mp4',
      'title': loc.translate('number_18_symbol'), 'title_sub': loc.translate('number_18_symbol_sub'),
    },
    {
      'id': '4', 'video': 'assets/videos/numbers_fixed/19.mp4',
      'title': loc.translate('number_19_symbol'), 'title_sub': loc.translate('number_19_symbol_sub'),
    },
  ];
}

class TwentyAndNumberData {
  final BuildContext context; TwentyAndNumberData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/20.mp4',
      'title': loc.translate('number_20_symbol'), 'title_sub': loc.translate('number_20_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/30.mp4',
      'title': loc.translate('number_30_symbol'), 'title_sub': loc.translate('number_30_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/40.mp4',
      'title': loc.translate('number_40_symbol'), 'title_sub': loc.translate('number_40_symbol_sub'),
    },
    {
      'id': '3', 'video': 'assets/videos/numbers_fixed/50.mp4',
      'title': loc.translate('number_50_symbol'), 'title_sub': loc.translate('number_50_symbol_sub'),
    },
    {
      'id': '4', 'video': 'assets/videos/numbers_fixed/60.mp4',
      'title': loc.translate('number_60_symbol'), 'title_sub': loc.translate('number_60_symbol_sub'),
    },
  ];
}

class TwentyAndNumber2Data {
  final BuildContext context; TwentyAndNumber2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/70.mp4',
      'title': loc.translate('number_70_symbol'), 'title_sub': loc.translate('number_70_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/80.mp4',
      'title': loc.translate('number_80_symbol'), 'title_sub': loc.translate('number_80_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/90.mp4',
      'title': loc.translate('number_90_symbol'), 'title_sub': loc.translate('number_90_symbol_sub'),
    },
    {
      'id': '3', 'video': 'assets/videos/numbers_fixed/100.mp4',
      'title': loc.translate('number_100_symbol'), 'title_sub': loc.translate('number_100_symbol_sub'),
    },
    {
      'id': '4', 'video': 'assets/videos/numbers_fixed/number.mp4',
      'title': loc.translate('number_symbol'), 'title_sub': loc.translate('number_symbol_sub'),
    },
  ];
}

class TwoHundredAndThousandData {
  final BuildContext context; TwoHundredAndThousandData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/200.mp4',
      'title': loc.translate('number_200_symbol'), 'title_sub': loc.translate('number_200_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/300.mp4',
      'title': loc.translate('number_300_symbol'), 'title_sub': loc.translate('number_300_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/400.mp4',
      'title': loc.translate('number_400_symbol'), 'title_sub': loc.translate('number_400_symbol_sub'),
    },
    {
      'id': '3', 'video': 'assets/videos/numbers_fixed/500.mp4',
      'title': loc.translate('number_500_symbol'), 'title_sub': loc.translate('number_500_symbol_sub'),
    },
    {
      'id': '4', 'video': 'assets/videos/numbers_fixed/600.mp4',
      'title': loc.translate('number_600_symbol'), 'title_sub': loc.translate('number_600_symbol_sub'),
    },
  ];
}

class TwoHundredAndThousand2Data {
  final BuildContext context; TwoHundredAndThousand2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/700.mp4',
      'title': loc.translate('number_700_symbol'), 'title_sub': loc.translate('number_700_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/800.mp4',
      'title': loc.translate('number_800_symbol'), 'title_sub': loc.translate('number_800_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/900.mp4',
      'title': loc.translate('number_900_symbol'), 'title_sub': loc.translate('number_900_symbol_sub'),
    },
    {
      'id': '3', 'video': 'assets/videos/numbers_fixed/1000.mp4',
      'title': loc.translate('number_1000_symbol'), 'title_sub': loc.translate('number_1000_symbol_sub'),
    },
    {
      'id': '4', 'video': 'assets/videos/numbers_fixed/thousand.mp4',
      'title': loc.translate('thousand_symbol'), 'title_sub': loc.translate('number_thousand_symbol_sub'),
    },
  ];
}

class TwoThousandAndThirdData {
  final BuildContext context; TwoThousandAndThirdData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/2000.mp4',
      'title': loc.translate('number_2000_symbol'), 'title_sub': loc.translate('number_2000_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/3000.mp4',
      'title': loc.translate('number_3000_symbol'), 'title_sub': loc.translate('number_3000_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/4000.mp4',
      'title': loc.translate('number_4000_symbol'), 'title_sub': loc.translate('number_4000_symbol_sub'),
    },
    {
      'id': '3', 'video': 'assets/videos/numbers_fixed/5000.mp4',
      'title': loc.translate('number_5000_symbol'), 'title_sub': loc.translate('number_5000_symbol_sub'),
    },
    {
      'id': '4', 'video': 'assets/videos/numbers_fixed/1000000.mp4',
      'title': loc.translate('number_one_million_symbol'), 'title_sub': loc.translate('number_1000000_symbol_sub'),
    },
  ];
}

class TwoThousandAndThird2Data {
  final BuildContext context; TwoThousandAndThird2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': 'assets/videos/numbers_fixed/first.mp4',
      'title': loc.translate('number_first_symbol'), 'title_sub': loc.translate('number_first_symbol_sub'),
    },
    {
      'id': '1', 'video': 'assets/videos/numbers_fixed/second.mp4',
      'title': loc.translate('number_second_symbol'), 'title_sub': loc.translate('number_second_symbol_sub'),
    },
    {
      'id': '2', 'video': 'assets/videos/numbers_fixed/third.mp4',
      'title': loc.translate('number_third_symbol'), 'title_sub': loc.translate('number_third_symbol_sub'),
    },
  ];
}

// =======================================================================
// 1 AND 10 LESSONS
// =======================================================================
class Num1Data {
  final BuildContext context; Num1Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': 'web/sign_lang_image/num_1.png', 'label': loc.translate('one') }, { 'image': 'web/sign_lang_image/num_4.png', 'label': loc.translate('four') },
    { 'image': 'web/sign_lang_image/num_2.png', 'label': loc.translate('two') }, { 'image': 'web/sign_lang_image/num_3.png', 'label': loc.translate('three') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum1 => { '0': item };
}

class Num2Data {
  final BuildContext context; Num2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': 'web/sign_lang_image/num_8.png', 'label': loc.translate('eight') }, { 'image': 'web/sign_lang_image/num_9.png',  'label': loc.translate('nine') },
    { 'image': 'web/sign_lang_image/num_5.png', 'label': loc.translate('five') }, { 'image': 'web/sign_lang_image/num_6.png', 'label': loc.translate('six') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum2 => { '0': item };
}

class Num3Data {
  final BuildContext context; Num3Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': 'web/sign_lang_image/num_10.png', 'label': loc.translate('ten') }, { 'image': 'web/sign_lang_image/num_11.png', 'label': loc.translate('eleven') },
    { 'image': 'web/sign_lang_image/num_12.png', 'label': loc.translate('twelve') }, { 'image': 'web/sign_lang_image/num_14.png', 'label': loc.translate('fourteen') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum3 => { '0': item };
}

class Num4Data {
  final BuildContext context; Num4Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': 'web/sign_lang_image/num_16.png', 'label': loc.translate('sixteen') }, { 'image': '', 'label': loc.translate('nineteen') },
    { 'image': 'web/sign_lang_image/num_17.png', 'label': loc.translate('seventeen') }, { 'image': '', 'label': loc.translate('eighteen') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum4 => { '0': item };
}

class Num5Data {
  final BuildContext context; Num5Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('twenty') }, { 'image': '', 'label': loc.translate('fifty') },
    { 'image': '', 'label': loc.translate('sixty') }, { 'image': '', 'label': loc.translate('thirty') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum5 => { '0': item };
}

class Num6Data {
  final BuildContext context; Num6Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('number') }, { 'image': '', 'label': loc.translate('ninety') },
    { 'image': '', 'label': loc.translate('seventy') }, { 'image': '', 'label': loc.translate('one_hundred') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum6 => { '0': item };
}

class Num7Data {
  final BuildContext context; Num7Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('five_hundred') }, { 'image': '', 'label': loc.translate('two_hundred') },
    { 'image': '', 'label': loc.translate('six_hundred') }, { 'image': '', 'label': loc.translate('four_hundred') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum7 => { '0': item };
}

class Num8Data {
  final BuildContext context; Num8Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('seven_hundred') }, { 'image': '', 'label': loc.translate('one_thousand') },
    { 'image': '', 'label': loc.translate('thousand') }, { 'image': '', 'label': loc.translate('nine_hundred') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum8 => { '0': item };
}

class Num9Data {
  final BuildContext context; Num9Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('two_thousand') }, { 'image': '', 'label': loc.translate('one_million') },
    { 'image': '', 'label': loc.translate('three_thousand') }, { 'image': '', 'label': loc.translate('five_thousand') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum9 => { '0': item };
}

class Num10Data {
  final BuildContext context; Num10Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('number') }, { 'image': '', 'label': loc.translate('second') },
    { 'image': '', 'label': loc.translate('third') }, { 'image': '', 'label': loc.translate('first') }
  ];
  Map<String, List<Map<String, dynamic>>> get storeNum10 => { '0': item };
}

class ExamNum1Data {
  final BuildContext context; ExamNum1Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': 'web/sign_lang_image/num_5.png' }, { 'id': '1', 'image': 'web/sign_lang_image/num_4.png' },
    { 'id': '2', 'image': 'web/sign_lang_image/num_9.png' }, { 'id': '3', 'image': 'web/sign_lang_image/num_7.png' },
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamNum1 => { '0': item };
}

class ExamNum2Data {
  final BuildContext context; ExamNum2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': 'web/sign_lang_image/num_15.png' },
    { 'id': '1', 'image': 'web/sign_lang_image/num_10.png' },
    { 'id': '2', 'image': 'web/sign_lang_image/num_17.png' },
    { 'id': '3', 'image': 'web/sign_lang_image/num_11.png' },
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamNum2 => { '0': item };
}

class ExamNum3Data {
  final BuildContext context; ExamNum3Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// num 70
    { 'id': '1', 'image': '' },// num 20
    { 'id': '2', 'image': '' },// num 80
    { 'id': '3', 'image': '' },// num 40
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamNum3 => { '0': item };
}

class ExamNum4Data {
  final BuildContext context; ExamNum4Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' },// num 700
    { 'id': '1', 'image': '' },// num 300
    { 'id': '2', 'image': '' },// num 900
    { 'id': '3', 'image': '' },// num 400
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamNum4 => { '0': item };
}

class ExamNum5Data {
  final BuildContext context; ExamNum5Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': 'web/sign_lang_image/num_0.png' },
    { 'id': '1', 'image': '' },// num first
    { 'id': '2', 'image': '' },// num second
    { 'id': '3', 'image': '' },// num first
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamNum5 => { '0': item };
}

// =======================================================================
// FAMILY LESSONS
// =======================================================================
class FamilyLessonsData {
  final BuildContext context; FamilyLessonsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get famLessonsItem => [
    {
      'id': 'fam_0', 'count': 10, 'image': '', // video family - children
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png',
      'titleKey': '${loc.translate('family')} - ${loc.translate('children')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_1', 'count': 10, 'image': '', // video child - boy
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 
      'titleKey': '${loc.translate('child')} - ${loc.translate('boy')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_2', 'count': 10, 'image': '', // video girl - cousin
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 
      'titleKey': '${loc.translate('girl')} - ${loc.translate('cousin')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_3', 'count': 10, 'image': '', // video niece - spouse
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png', 
      'titleKey': '${loc.translate('niece')} - ${loc.translate('spouse')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_4', 'count': 10, 'image': '', // video divorce - poor
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png',
      'titleKey': '${loc.translate('divorce')} - ${loc.translate('poor')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_5', 'count': 10, 'image': '', // video to_respect - tall
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png',
      'titleKey': '${loc.translate('to_respect')} - ${loc.translate('tall')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_6', 'count': 7, 'image': '', // video little - to_die
      'imageTime': 'web/icons/time.png', 'imageHand': 'web/icons/hand.png',
      'titleKey': '${loc.translate('little')} - ${loc.translate('to_die')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    }
  ];
  Map<String, List<Map<String, dynamic>>> get storesByFamLessons => { '0': famLessonsItem };
}

class FamAndChildrenData {
  final BuildContext context; FamAndChildrenData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // family
      'title': loc.translate('words_family_symbol'), 'title_sub': loc.translate('words_family_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // father
      'title': loc.translate('words_father_symbol'), 'title_sub': loc.translate('words_father_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // mother
      'title': loc.translate('words_mother_symbol'), 'title_sub': loc.translate('words_mother_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // parents
      'title': loc.translate('words_parents_symbol'), 'title_sub': loc.translate('words_parents_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // brother
      'title': loc.translate('words_brother_symbol'), 'title_sub': loc.translate('words_brother_symbol_sub'),
    },
  ];
}

class FamAndChildren2Data {
  final BuildContext context; FamAndChildren2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // sister
      'title': loc.translate('words_sister_symbol'), 'title_sub': loc.translate('words_sister_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // siblings
      'title': loc.translate('words_siblings_symbol'), 'title_sub': loc.translate('words_siblings_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // son
      'title': loc.translate('words_son_symbol'), 'title_sub': loc.translate('words_son_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // daughter
      'title': loc.translate('words_daughter_symbol'), 'title_sub': loc.translate('words_daughter_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // children
      'title': loc.translate('words_children_symbol'), 'title_sub': loc.translate('words_children_symbol_sub'),
    },
  ];
}

class ChildAndBoyData {
  final BuildContext context; ChildAndBoyData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // child
      'title': loc.translate('words_child_symbol'), 'title_sub': loc.translate('words_child_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // baby
      'title': loc.translate('words_baby_symbol'), 'title_sub': loc.translate('words_baby_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // elder_brother
      'title': loc.translate('words_elder_brother_symbol'), 'title_sub': loc.translate('words_elder_brother_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // elder_sister
      'title': loc.translate('words_elder_sister_symbol'), 'title_sub': loc.translate('words_elder_sister_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // younger_brother
      'title': loc.translate('words_younger_brother_symbol'), 'title_sub': loc.translate('words_younger_brother_symbol_sub'),
    },
  ];
}

class ChildAndBoy2Data {
  final BuildContext context; ChildAndBoy2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // younger_sister
      'title': loc.translate('words_younger_sister_symbol'), 'title_sub': loc.translate('words_younger_sister_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // person
      'title': loc.translate('words_person_symbol'), 'title_sub': loc.translate('words_person_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // man
      'title': loc.translate('words_man_symbol'), 'title_sub': loc.translate('words_man_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // woman
      'title': loc.translate('words_woman_symbol'), 'title_sub': loc.translate('words_woman_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // boy
      'title': loc.translate('words_boy_symbol'), 'title_sub': loc.translate('words_boy_symbol_sub'),
    },
  ];
}

class GirlAndCousinData {
  final BuildContext context; GirlAndCousinData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // girl
      'title': loc.translate('words_girl_symbol'), 'title_sub': loc.translate('words_girl_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // twin
      'title': loc.translate('words_twin_symbol'), 'title_sub': loc.translate('words_twin_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // twin_brother
      'title': loc.translate('words_twin_brother_symbol'), 'title_sub': loc.translate('words_twin_brother_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // twin_sister
      'title': loc.translate('words_twin_sister_symbol'), 'title_sub': loc.translate('words_twin_sister_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // grandfather
      'title': loc.translate('words_grandfather_symbol'), 'title_sub': loc.translate('words_grandfather_symbol_sub'),
    },
  ];
}

class GirlAndCousin2Data {
  final BuildContext context; GirlAndCousin2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // grandmother
      'title': loc.translate('words_grandmother_symbol'), 'title_sub': loc.translate('words_grandmother_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // grandparents
      'title': loc.translate('words_grandparents_symbol'), 'title_sub': loc.translate('words_grandparents_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // uncle
      'title': loc.translate('words_uncle_symbol'), 'title_sub': loc.translate('words_uncle_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // aunt
      'title': loc.translate('words_aunt_symbol'), 'title_sub': loc.translate('words_aunt_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // cousin
      'title': loc.translate('words_cousin_symbol'), 'title_sub': loc.translate('words_cousin_symbol_sub'),
    },
  ];
}

class NieceAndSpouseData {
  final BuildContext context; NieceAndSpouseData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // niece
      'title': loc.translate('words_niece_symbol'), 'title_sub': loc.translate('words_niece_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // nephew
      'title': loc.translate('words_nephew_symbol'), 'title_sub': loc.translate('words_nephew_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // relative
      'title': loc.translate('words_relative_symbol'), 'title_sub': loc.translate('words_relative_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // countrywoman
      'title': loc.translate('words_countrywoman_symbol'), 'title_sub': loc.translate('words_countrywoman_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // generation
      'title': loc.translate('words_generation_symbol'), 'title_sub': loc.translate('words_generation_symbol_sub'),
    },
  ];
}

class NieceAndSpouse2Data {
  final BuildContext context; NieceAndSpouse2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // teenager
      'title': loc.translate('words_teenager_symbol'), 'title_sub': loc.translate('words_teenager_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // bride
      'title': loc.translate('words_bride_symbol'), 'title_sub': loc.translate('words_bride_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // groom
      'title': loc.translate('words_groom_symbol'), 'title_sub': loc.translate('words_groom_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // marriage
      'title': loc.translate('words_marriage_symbol'), 'title_sub': loc.translate('words_marriage_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // spouse
      'title': loc.translate('words_spouse_symbol'), 'title_sub': loc.translate('words_spouse_symbol_sub'),
    },
  ];
}

class DivorceAndPoorData {
  final BuildContext context; DivorceAndPoorData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // divorce
      'title': loc.translate('words_divorce_symbol'), 'title_sub': loc.translate('words_divorce_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // bachelor
      'title': loc.translate('words_bachelor_symbol'), 'title_sub': loc.translate('words_bachelor_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // lover
      'title': loc.translate('words_lover_symbol'), 'title_sub': loc.translate('words_lover_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // pretty
      'title': loc.translate('words_pretty_symbol'), 'title_sub': loc.translate('words_pretty_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // husband
      'title': loc.translate('words_husband_symbol'), 'title_sub': loc.translate('words_husband_symbol_sub'),
    },
  ];
}

class DivorceAndPoor2Data {
  final BuildContext context; DivorceAndPoor2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // wife
      'title': loc.translate('words_wife_symbol'), 'title_sub': loc.translate('words_wife_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // youth
      'title': loc.translate('words_youth_symbol'), 'title_sub': loc.translate('words_youth_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // unfortunate
      'title': loc.translate('words_unfortunate_symbol'), 'title_sub': loc.translate('words_unfortunate_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // rich
      'title': loc.translate('words_rich_symbol'), 'title_sub': loc.translate('words_rich_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // poor
      'title': loc.translate('words_poor_symbol'), 'title_sub': loc.translate('words_poor_symbol_sub'),
    },
  ];
}

class ToRespectAndTallData {
  final BuildContext context; ToRespectAndTallData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // to_respect
      'title': loc.translate('words_to_respect_symbol'), 'title_sub': loc.translate('words_to_respect_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // to_live
      'title': loc.translate('words_to_live_symbol'), 'title_sub': loc.translate('words_to_live_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // grown_up
      'title': loc.translate('words_grown_up_symbol'), 'title_sub': loc.translate('words_grown_up_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // adult
      'title': loc.translate('words_adult_symbol'), 'title_sub': loc.translate('words_adult_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // elder
      'title': loc.translate('words_elder_symbol'), 'title_sub': loc.translate('words_elder_symbol_sub'),
    },
  ];
}

class ToRespectAndTall2Data {
  final BuildContext context; ToRespectAndTall2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // younger
      'title': loc.translate('words_younger_symbol'), 'title_sub': loc.translate('words_younger_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // widow
      'title': loc.translate('words_widow_symbol'), 'title_sub': loc.translate('words_widow_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // widower
      'title': loc.translate('words_widower_symbol'), 'title_sub': loc.translate('words_widower_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // to_be_born
      'title': loc.translate('words_to_be_born_symbol'), 'title_sub': loc.translate('words_to_be_born_symbol_sub'),
    },
    {
      'id': '4', 'video': '', // tall
      'title': loc.translate('words_tall_symbol'), 'title_sub': loc.translate('words_tall_symbol_sub'),
    },
  ];
}

class LittleAndToDieData {
  final BuildContext context; LittleAndToDieData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // little
      'title': loc.translate('words_little_symbol'), 'title_sub': loc.translate('words_little_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // thick
      'title': loc.translate('words_thick_symbol'), 'title_sub': loc.translate('words_thick_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // ill
      'title': loc.translate('words_ill_symbol'), 'title_sub': loc.translate('words_ill_symbol_sub'),
    },
    {
      'id': '3', 'video': '', // thin
      'title': loc.translate('words_thin_symbol'), 'title_sub': loc.translate('words_thin_symbol_sub'),
    }
  ];
}

class LittleAndToDie2Data {
  final BuildContext context; LittleAndToDie2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    {
      'id': '0', 'video': '', // young
      'title': loc.translate('words_young_symbol'), 'title_sub': loc.translate('words_young_symbol_sub'),
    },
    {
      'id': '1', 'video': '', // death
      'title': loc.translate('words_death_symbol'), 'title_sub': loc.translate('words_death_symbol_sub'),
    },
    {
      'id': '2', 'video': '', // to_die
      'title': loc.translate('words_to_die_symbol'), 'title_sub': loc.translate('words_to_die_symbol_sub'),
    }
  ];
}

// =======================================================================
// WORDS
// =======================================================================
class Words1Data {
  final BuildContext context; Words1Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('family') }, { 'image': '', 'label': loc.translate('parents') },
    { 'image': '', 'label': loc.translate('brother') }, { 'image': '', 'label': loc.translate('father') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words2Data {
  final BuildContext context; Words2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('son') }, { 'image': '', 'label': loc.translate('siblings') },
    { 'image': '', 'label': loc.translate('daughter') }, { 'image': '', 'label': loc.translate('children') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words3Data {
  final BuildContext context; Words3Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('elder_sister') }, { 'image': '', 'label': loc.translate('child') },
    { 'image': '', 'label': loc.translate('elder_brother') }, { 'image': '', 'label': loc.translate('younger_brother') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words4Data {
  final BuildContext context; Words4Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('woman') }, { 'image': '', 'label': loc.translate('boy') },
    { 'image': '', 'label': loc.translate('person') }, { 'image': '', 'label': loc.translate('man') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words5Data {
  final BuildContext context; Words5Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('twin_brother') }, { 'image': '', 'label': loc.translate('girl') },
    { 'image': '', 'label': loc.translate('twin_sister') }, { 'image': '', 'label': loc.translate('grandfather') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words6Data {
  final BuildContext context; Words6Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('cousin') }, { 'image': '', 'label': loc.translate('uncle') },
    { 'image': '', 'label': loc.translate('grandparents') }, { 'image': '', 'label': loc.translate('aunt') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words7Data {
  final BuildContext context; Words7Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('generation') }, { 'image': '', 'label': loc.translate('niece') },
    { 'image': '', 'label': loc.translate('countrywoman') }, { 'image': '', 'label': loc.translate('relative') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words8Data {
  final BuildContext context; Words8Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('spouse') }, { 'image': '', 'label': loc.translate('marriage') },
    { 'image': '', 'label': loc.translate('groom') }, { 'image': '', 'label': loc.translate('teenager') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words9Data {
  final BuildContext context; Words9Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('bachelor') }, { 'image': '', 'label': loc.translate('divorce') },
    { 'image': '', 'label': loc.translate('pretty') }, { 'image': '', 'label': loc.translate('husband') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words10Data {
  final BuildContext context; Words10Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('youth') }, { 'image': '', 'label': loc.translate('unfortunate') },
    { 'image': '', 'label': loc.translate('wife') }, { 'image': '', 'label': loc.translate('poor') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words1Data1 {
  final BuildContext context; Words1Data1({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('elder') }, { 'image': '', 'label': loc.translate('to_respect') },
    { 'image': '', 'label': loc.translate('adult') }, { 'image': '', 'label': loc.translate('to_live') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words1Data2 {
  final BuildContext context; Words1Data2({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('tall') }, { 'image': '', 'label': loc.translate('widow') },
    { 'image': '', 'label': loc.translate('widower') }, { 'image': '', 'label': loc.translate('younger') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words1Data3 {
  final BuildContext context; Words1Data3({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('little') }, { 'image': '', 'label': loc.translate('thick') },
    { 'image': '', 'label': loc.translate('ill') }, { 'image': '', 'label': loc.translate('thin') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class Words1Data4 {
  final BuildContext context; Words1Data4({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'image': '', 'label': loc.translate('death') }, { 'image': '', 'label': loc.translate('to_die') },
    { 'image': '', 'label': loc.translate('young') }, { 'image': '', 'label': loc.translate('thick') },
  ];
  Map<String, List<Map<String, dynamic>>> get storeWords => { '0': item };
}

class ExamWords1Data {
  final BuildContext context; ExamWords1Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' }, // daughter
    { 'id': '1', 'image': '' }, // mother
    { 'id': '2', 'image': '' }, // sister
    { 'id': '3', 'image': '' }, // brother
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamWords2Data {
  final BuildContext context; ExamWords2Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' }, // elder_brother
    { 'id': '1', 'image': '' }, // man
    { 'id': '2', 'image': '' }, // younger_brother
    { 'id': '3', 'image': '' }, // boy
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamWords3Data {
  final BuildContext context; ExamWords3Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' }, // girl
    { 'id': '1', 'image': '' }, // uncle
    { 'id': '2', 'image': '' }, // cousin
    { 'id': '3', 'image': '' }, // grandmother
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamWords4Data {
  final BuildContext context; ExamWords4Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' }, // bride
    { 'id': '1', 'image': '' }, // countrywoman
    { 'id': '2', 'image': '' }, // relative
    { 'id': '3', 'image': '' }, // spouse
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamWords5Data {
  final BuildContext context; ExamWords5Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' }, // unfortunate
    { 'id': '1', 'image': '' }, // poor
    { 'id': '2', 'image': '' }, // bachelor
    { 'id': '3', 'image': '' }, // rich
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamWords6Data {
  final BuildContext context; ExamWords6Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' }, // unfortunate
    { 'id': '1', 'image': '' }, // poor
    { 'id': '2', 'image': '' }, // bachelor
    { 'id': '3', 'image': '' }, // rich
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}

class ExamWords7Data {
  final BuildContext context; ExamWords7Data({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get item => [
    { 'id': '0', 'image': '' }, // thin
    { 'id': '1', 'image': '' }, // thick
    { 'id': '2', 'image': '' }, // young
    { 'id': '3', 'image': '' }, // little
  ];
  Map<String, List<Map<String, dynamic>>> get storeExamWords => { '0': item };
}
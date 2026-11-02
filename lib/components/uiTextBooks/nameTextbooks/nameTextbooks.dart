import 'package:flutter/cupertino.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_textbooks.dart';
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
  void markCompletedOnServer(String id) { if (!_completed.contains(id)) { _completed.add(id); _prefs?.setStringList('lp_completed', _completed.toList()); _incrementLessonsToday(); } }
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
    int sumOf(List<Map<String, dynamic>> items) => items.where((i) => isCompleted('${i['id']}')).fold(0, (sum, i) => sum + (int.tryParse('${i['count']}') ?? 0));
    final books = [AlphabetLessonsData(context: context).alphabetLessonsItem, NumbersLessonsData(context: context).numLessonsItem, FamilyLessonsData(context: context).famLessonsItem, FoodLessonsData(context: context).item, FeelingsLessonsData(context: context).item];
    for (int k = 0; k < books.length; k++) { _learned['$k'] = sumOf(books[k]); }
    _saveLearned();
    if (books.any((b) => b.isNotEmpty && b.every((i) => isCompleted('${i['id']}')))) _prefs?.setBool(AchievementService.kTextbookDone, true);
  }

  /// Adds lessons the account completed on the server (e.g. on another phone).
  void restoreCompleted(Iterable<String> ids) { _completed.addAll(ids); _prefs?.setStringList('lp_completed', _completed.toList()); }

  /// Forgets this phone's progress (another account logged in, or log out).
  void clearLocal() { _completed.clear(); _learned.clear(); resetStats(); }

  void resetStats() { imolar = 0; ballar = 0; mistakes = 0; _startedAt = DateTime.now(); _resultSent = false; }
}

// =======================================================================
// Lessons Textbooks data
// =======================================================================
class LessonsTextbooksData {
  final BuildContext context; LessonsTextbooksData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  /// The textbook cards, from the dashboard (see ServerTextbooks.cards); the app's Alphabet, Numbers and Introduction always stay
  List<Map<String, dynamic>> get lessonsTextbooksItems => ServerTextbooks.cards(_appTextbooks, Localizations.localeOf(context).languageCode);
  List<Map<String, dynamic>> get _appTextbooks => [
    {
      'id': '0', 'image': 'assets/textbooks/alphabet.webp', 'imageWidth': 115.0, 'imageRight': -10, 'titleKey': loc.translate('alphabet'), 'subKey': loc.translate('alphabet_sub'),
      'letter': loc.translate('letter_learned'), 'learned': LessonProgress.instance.learnedOf('0'), 'total': 28,
    },
    {
      'id': '1', 'image': 'assets/textbooks/numbers.webp', 'imageWidth': 115.0, 'imageRight': -15, 'titleKey': loc.translate('numbers'), 'subKey': '+ ${loc.translate('numbers')}',
      'letter': loc.translate('numbers_sub'), 'learned': LessonProgress.instance.learnedOf('1'), 'total': 48,
    },
    {
      'id': '2', 'image': 'web/images/introduction.webp', 'imageWidth': 115.0, 'imageRight': -20, 'titleKey': loc.translate('introduction'), 'subKey': loc.translate('words'),
      'letter': loc.translate('words_learn'), 'learned': LessonProgress.instance.learnedOf('2'), 'total': 67,
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storesByLessonsTextbooks => { '0': lessonsTextbooksItems, };
}

class OneLessonsGreatData {
  final BuildContext context; OneLessonsGreatData({required this.context}); AppLocalizations get localizations => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get oneLessonsGreatItem => [
    { 'id': '0', 'image': 'web/icons/hand.webp', 'title': localizations.translate('gestures') }, { 'id': '1', 'image': 'web/icons/lightning.webp', 'title': localizations.translate('points') },
    { 'id': '2', 'image': 'web/icons/star.webp', 'title': localizations.translate('result') }
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
      'id': 'alp_0', 'count': 1, 'image': '', // video A - E
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': 'A - E ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '4 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_1', 'count': 1, 'image': '', // video F - I
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': 'F - I ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_2', 'count': 1, 'image': '', // video J - M
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': 'J - M ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_3', 'count': 1, 'image': '', // video N - Q
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': 'N - Q ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_4', 'count': 1, 'image': '', // video R - U
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': 'R - U ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_5', 'count': 1, 'image': '', // video V - Z
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': 'V - Z ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'alp_6', 'count': 1, 'image': '', // video O`- NG
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': 'O` - NG ${loc.translate('alphabet_little')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storesByAlphabetLessons => { '0': alphabetLessonsItem };
}


// =======================================================================
// NUMBERS LESSONS
// =======================================================================
class NumbersLessonsData {
  final BuildContext context; NumbersLessonsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get numLessonsItem => [
    {
      'id': 'num_0', 'count': 1, 'image': '', // video 0 - 9
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': '0 - 9 ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'num_1', 'count': 1, 'image': '', // video 10 - 19
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': '10 - 19 ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'num_2', 'count': 1, 'image': '', // video 20 - number
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': '20 - ${loc.translate('number')} ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'num_3', 'count': 1, 'image': '', // video 200 - thousand
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': '200 - ${loc.translate('thousand')} ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'num_4', 'count': 1, 'image': '', // video 2000 - third
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 'titleKey': '2000 - ${loc.translate('third')} ${loc.translate('numbers_sub_title')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
  ];
  Map<String, List<Map<String, dynamic>>> get storesByNumLessons => { '0': numLessonsItem };
}

// =======================================================================
// FAMILY LESSONS
// =======================================================================
class FamilyLessonsData {
  final BuildContext context; FamilyLessonsData({required this.context}); AppLocalizations get loc => AppLocalizations.of(context)!;
  List<Map<String, dynamic>> get famLessonsItem => [
    {
      'id': 'fam_0', 'count': 1, 'image': '', // video family - children
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp',
      'titleKey': '${loc.translate('family')} - ${loc.translate('children')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_1', 'count': 1, 'image': '', // video child - boy
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 
      'titleKey': '${loc.translate('child')} - ${loc.translate('boy')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_2', 'count': 1, 'image': '', // video girl - cousin
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 
      'titleKey': '${loc.translate('girl')} - ${loc.translate('cousin')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_3', 'count': 1, 'image': '', // video niece - spouse
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp', 
      'titleKey': '${loc.translate('niece')} - ${loc.translate('spouse')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_4', 'count': 1, 'image': '', // video divorce - poor
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp',
      'titleKey': '${loc.translate('divorce')} - ${loc.translate('poor')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_5', 'count': 1, 'image': '', // video to_respect - tall
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp',
      'titleKey': '${loc.translate('to_respect')} - ${loc.translate('tall')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    },
    {
      'id': 'fam_6', 'count': 1, 'image': '', // video little - to_die
      'imageTime': 'web/icons/time.webp', 'imageHand': 'web/icons/hand.webp',
      'titleKey': '${loc.translate('little')} - ${loc.translate('to_die')} ${loc.translate('words')}', 'time': '5 ${loc.translate('time_min')}', 'click': '10 ${loc.translate('hints')}'
    }
  ];
  Map<String, List<Map<String, dynamic>>> get storesByFamLessons => { '0': famLessonsItem };
}

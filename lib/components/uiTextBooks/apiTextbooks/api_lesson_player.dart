import 'package:flutter/material.dart';

import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/choose_image_exercise.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/choose_text_exercise.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/lesson_parts.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/matching_exercise.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/order_exercise.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'package:signlang/components/web/day/today.dart';
import 'package:signlang/components/web/loading/bookLoading.dart';
import 'package:signlang/components/web/saved/saved.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/achievement_service.dart';
import 'package:signlang/services/statistics_service.dart';
import 'package:signlang/services/theme_service.dart';

const Color _blue = Color(0xFF4A7FD0);

/// Plays a lesson made in the dashboard's lesson builder, with the 4 exercise templates in
/// lessonTemplates/. Answers are checked by the server; finishing saves progress, XP, streak and achievements.
class ApiLessonPlayer extends StatefulWidget {
  final int lessonId;
  final String title;
  const ApiLessonPlayer({super.key, required this.lessonId, required this.title});

  @override
  State<ApiLessonPlayer> createState() => _ApiLessonPlayerState();
}

class _ApiLessonPlayerState extends State<ApiLessonPlayer> {
  ApiLessonDetail? _lesson;
  int? _attemptId;
  bool _failed = false;
  int _index = 0;
  // The answer the learner has put together for the current exercise (null = not ready)
  Map<String, dynamic>? _answer;
  // The server's verdict once "Check" was pressed
  AnswerResult? _result;
  bool _busy = false;
  bool _saved = false;

  // the texts come in the app language, which is read from the context
  bool _started = false;
  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) { _started = true; _start(); }
  }

  Future<void> _start() async {
    LessonProgress.instance.resetStats();
    setState(() { _failed = false; _lesson = null; _index = 0; _answer = null; _result = null; _saved = false; });
    try {
      final results = await Future.wait([UzslApi.lesson(widget.lessonId, lang: _lang), UzslApi.startAttempt(widget.lessonId)]);
      if (!mounted) return;
      setState(() { _lesson = results[0] as ApiLessonDetail; _attemptId = results[1] as int; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _failed = true);
      showApiError(context, e, onRetry: _start);
    }
  }

  Future<void> _check() async {
    final lesson = _lesson, answer = _answer, attemptId = _attemptId;
    if (lesson == null || answer == null || attemptId == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await UzslApi.answer(attemptId, lesson.exercises[_index].id, answer, lang: _lang);
      // local points / mistakes, like the app's own lessons (statistics, "perfect lesson" achievement)
      result.isCorrect ? LessonProgress.instance.addCorrect() : LessonProgress.instance.addWrong();
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e, onRetry: _check);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    final lesson = _lesson!;
    if (_index + 1 < lesson.exercises.length) {
      setState(() { _index++; _answer = null; _result = null; _saved = false; });
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await UzslApi.finish(_attemptId!);
      await StatisticsService.instance.addStudyTime(5);
      await AchievementService.instance.recordLessonFinished(perfect: LessonProgress.instance.mistakes == 0 && LessonProgress.instance.imolar > 0);
      if (!mounted) return;
      final again = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ApiLessonResultScreen(result: result)));
      if (!mounted) return;
      if (again == true) { _start(); return; }
      // first lesson of the day: the streak screen, like the app's own lessons
      if (!await StreakManager.alreadyShownToday()) {
        await StreakManager.recordCompletion();
        await StreakManager.markShownToday();
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Today()));
      } else if (mounted) {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e, onRetry: _next);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmQuit() async {
    if (await showQuitLessonDialog(context) && mounted) Navigator.pop(context);
  }

  // ===== what the right answer was (for the red banner and the bookmark) =====
  String? _correctText(ApiExercise exercise, AnswerResult result) {
    final byId = {for (final o in exercise.options) o.id: o};
    if (result.correctOptionId != null) return byId[result.correctOptionId]?.text;
    if (result.correctOrder != null) return result.correctOrder!.map((id) => byId[id]?.text ?? '').join(' ');
    return null;
  }

  Future<void> _save(ApiExercise exercise) async {
    final result = _result;
    final word = result == null ? null : _correctText(exercise, result);
    if (word == null || word.isEmpty) return;
    await SavedStore.instance.toggle({'word': word, 'type': 'word', 'source': 'textbook'});
    if (mounted) setState(() => _saved = !_saved);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lesson = _lesson;
    return PopScope(
      canPop: lesson == null,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _confirmQuit(); },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: lesson == null
                ? Center(child: _failed ? _loadFailed(loc) : BookLoader(label: loc.translate('loading')))
                : _player(loc, lesson),
          ),
        ),
      ),
    );
  }

  Widget _loadFailed(AppLocalizations loc) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(loc.translate('lesson_load_failed'), style: const TextStyle(fontSize: 17)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _start, child: Text(loc.translate('try_again'))),
      TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.translate('back'))),
    ],
  );

  Widget _player(AppLocalizations loc, ApiLessonDetail lesson) {
    final exercise = lesson.exercises[_index];
    final result = _result;
    final String question = exercise.prompt?.isNotEmpty == true
        ? exercise.prompt!
        : loc.translate(switch (exercise.type) { 'matching' => 'match_hint', 'order' => 'order_hint', _ => 'choose_right_answer' });
    void onAnswer(Map<String, dynamic>? a) => setState(() => _answer = a);
    final Widget body = switch (exercise.type) {
      'chooseText' => ChooseTextExercise(exercise: exercise, result: result, question: question, onAnswer: onAnswer),
      'chooseImage' => ChooseImageExercise(exercise: exercise, result: result, question: question, onAnswer: onAnswer),
      'order' => OrderExercise(exercise: exercise, result: result, question: question, onAnswer: onAnswer),
      'matching' => MatchingExercise(exercise: exercise, result: result, question: question, onAnswer: onAnswer),
      _ => const SizedBox.shrink(),
    };
    final bool canSave = result != null && (_correctText(exercise, result)?.isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // ===== 1) close · progress · bookmark =====
          LessonTopBar(index: _index, total: lesson.exercises.length, onClose: _confirmQuit, onSave: canSave ? () => _save(exercise) : null, saved: _saved),
          const SizedBox(height: 16),
          // ===== 2) the exercise =====
          Expanded(
            child: SingleChildScrollView(
              // each exercise gets fresh state (selection, video)
              child: KeyedSubtree(key: ValueKey(exercise.id), child: body),
            ),
          ),
          // ===== 3) verdict + button =====
          if (result != null) ...[
            const SizedBox(height: 10),
            LessonFeedbackBanner(isCorrect: result.isCorrect, correctAnswer: _correctText(exercise, result), explanation: result.explanation),
          ],
          const SizedBox(height: 12),
          LessonCheckButton(
            checked: result != null, isCorrect: result?.isCorrect, canCheck: _answer != null, busy: _busy,
            last: _index + 1 >= lesson.exercises.length, onCheck: _check, onNext: _next,
          ),
        ],
      ),
    );
  }
}

// ======================== result ========================
/// Shown after the last exercise. Pops true for "Try again".
class ApiLessonResultScreen extends StatelessWidget {
  final LessonResult result;
  const ApiLessonResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Widget stat(String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.grey[600]!))),
        ]),
      ),
    );
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Spacer(),
                Image.asset('web/images/well_done.png', height: 200),
                const SizedBox(height: 20),
                Text(loc.translate(result.passed ? 'lessons_over' : 'wrong'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Row(children: [
                  stat(loc.translate('correct_answer'), '${result.correct}/${result.total}'),
                  const SizedBox(width: 10),
                  stat('%', '${result.accuracy}%'),
                  const SizedBox(width: 10),
                  stat(loc.translate('points'), loc.translate('xp_earned').replaceAll('{n}', '${result.xpEarned}')),
                ]),
                for (final name in result.unlockedAchievements) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFFFF8E1)), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Image.asset('web/images/fire.png', width: 28, height: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Text(loc.translate('achievement_unlocked').replaceAll('{name}', name), style: const TextStyle(fontWeight: FontWeight.w600))),
                    ]),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                    ),
                    child: Text(loc.translate('continue'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppPalette.bg(Colors.grey).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Colors.grey).withValues(alpha: 0.9),
                      side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(loc.translate('try_again'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

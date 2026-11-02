import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_lesson_result.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/choose_image_exercise.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/choose_text_exercise.dart';
import 'package:signlang/components/uiTextBooks/lessonTemplates/learn_exercise.dart';
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

/// Plays a lesson made in the dashboard's lesson builder, with the 5 exercise templates in
/// lessonTemplates/. Answers are checked by the server; finishing saves progress, XP, streak and achievements.
class ApiLessonPlayer extends StatefulWidget {
  final int lessonId;
  final String title;

  /// The "About lesson" page under the player: closed together with it
  final Route<dynamic>? intro;
  const ApiLessonPlayer({super.key, required this.lessonId, required this.title, this.intro});

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
  // a "Check" request is on its way (the button shows [_busy] only if it takes long)
  bool _checking = false;
  bool _saved = false;
  // the next exercise is sliding in: the button waits hidden until it has arrived
  bool _switching = false;
  Timer? _switchTimer;
  // "learn" exercises: the slide shown in the carousel
  final CarouselSliderController _slides = CarouselSliderController();
  int _slide = 0;
  final ScrollController _scroll = ScrollController();
  // set after the last exercise: the result is shown in place of the exercises
  LessonResult? _finished;

  // the texts come in the app language, which is read from the context
  bool _started = false;
  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void dispose() { _switchTimer?.cancel(); _scroll.dispose(); super.dispose(); }

  @override
  void didChangeDependencies() { super.didChangeDependencies(); if (!_started) { _started = true; _start(); } }

  Future<void> _start() async {
    LessonProgress.instance.resetStats();
    setState(() { _failed = false; _lesson = null; _finished = null; _index = 0; _answer = null; _result = null; _saved = false; _slide = 0; });
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
    if (lesson == null || answer == null || attemptId == null || _checking) return;
    _checking = true;
    // the spinner only when the server is slow: a quick answer shows the verdict without the button flashing
    final spinner = Timer(const Duration(milliseconds: 400), () { if (mounted && _checking) setState(() => _busy = true); });
    try {
      final result = await UzslApi.answer(attemptId, lesson.exercises[_index].id, answer, lang: _lang);
      // local points / mistakes, like the app's own lessons (statistics, "perfect lesson" achievement)
      result.isCorrect ? LessonProgress.instance.addCorrect() : LessonProgress.instance.addWrong();
      if (mounted) setState(() { _result = result; _busy = false; });
    } on ApiException catch (e) {
      if (mounted) { setState(() => _busy = false); showApiError(context, e, onRetry: _check); }
    } finally { spinner.cancel(); _checking = false; }
  }

  Future<void> _next() async {
    final lesson = _lesson!;
    if (_index + 1 < lesson.exercises.length) {
      setState(() { _index++; _answer = null; _result = null; _saved = false; _slide = 0; _switching = true; });
      // same length as the exercise's slide-in
      _switchTimer?.cancel();
      _switchTimer = Timer(const Duration(milliseconds: 380), () { if (mounted) setState(() => _switching = false); });
      // the next exercise starts at its top
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await UzslApi.finish(_attemptId!);
      if (mounted) setState(() => _finished = result);
      // saved on the phone in the background: the result shows without waiting for them
      unawaited(StatisticsService.instance.addStudyTime(5));
      unawaited(AchievementService.instance.recordLessonFinished(perfect: LessonProgress.instance.mistakes == 0 && LessonProgress.instance.imolar > 0));
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e, onRetry: _next);
    } finally { if (mounted) setState(() => _busy = false); }
  }

  // "Continue" on the result: the streak screen on the first lesson of the day, like the app's own lessons
  Future<void> _leave() async {
    if (!await StreakManager.alreadyShownToday()) {
      await StreakManager.recordCompletion();
      await StreakManager.markShownToday();
      if (!mounted) return;
      _removeIntro();
      Navigator.pushReplacement(context, lessonRoute(const Today()));
    } else if (mounted) { _close(); }
  }

  // the intro goes without an animation, then the player slides away in one step
  void _removeIntro() { final intro = widget.intro; if (intro != null && intro.isActive) Navigator.of(context).removeRoute(intro); }

  void _close() { _removeIntro(); Navigator.pop(context); }

  // "learn" slides aren't answered: the button walks through them, then goes on like "Next question"
  void _learnNext(ApiExercise exercise) {
    if (_slide + 1 < exercise.options.length) { _slides.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic); }
    else { _next(); }
  }

  Future<void> _confirmQuit() async { if (await showQuitLessonDialog(context) && mounted) _close(); }

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
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _finished != null ? _close() : _confirmQuit(); },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
              child: _finished != null ? ApiLessonResultView(key: const ValueKey('result'), result: _finished!, onContinue: _leave, onAgain: _start) : lesson == null
                ? Center(key: const ValueKey('loading'), child: _failed ? _loadFailed(loc) : BookLoader(label: loc.translate('loading')))
                : KeyedSubtree(key: const ValueKey('player'), child: _player(loc, lesson))
            )
          )
        )
      )
    );
  }

  Widget _loadFailed(AppLocalizations loc) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(loc.translate('lesson_load_failed'), style: const TextStyle(fontSize: 17)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _start, child: Text(loc.translate('try_again'))),
      TextButton(onPressed: _close, child: Text(loc.translate('back'))),
    ],
  );

  Widget _player(AppLocalizations loc, ApiLessonDetail lesson) {
    final exercise = lesson.exercises[_index];
    final result = _result;
    final String question = exercise.prompt?.isNotEmpty == true ? exercise.prompt! : loc.translate(switch (exercise.type) { 'matching' => 'match_hint', 'order' => 'order_hint', _ => 'choose_right_answer' });
    void onAnswer(Map<String, dynamic>? a) => setState(() => _answer = a);
    final Widget body = switch (exercise.type) {
      'chooseText' => ChooseTextExercise(exercise: exercise, result: result, question: question, onAnswer: onAnswer),
      'chooseImage' => ChooseImageExercise(exercise: exercise, result: result, question: question, onAnswer: onAnswer),
      'order' => OrderExercise(exercise: exercise, result: result, question: question, onAnswer: onAnswer),
      'matching' => MatchingExercise(exercise: exercise, result: result, question: question, onAnswer: onAnswer),
      'learn' => LearnExercise(exercise: exercise, controller: _slides, onSlide: (i) => setState(() => _slide = i)),
      _ => const SizedBox.shrink(),
    };
    final bool learn = exercise.type == 'learn';
    final bool lastExercise = _index + 1 >= lesson.exercises.length;
    final bool canSave = result != null && (_correctText(exercise, result)?.isNotEmpty ?? false);

    const side = EdgeInsets.symmetric(horizontal: 16);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // ===== 1) close · progress · bookmark =====
          Padding(padding: side, child: LessonTopBar(index: _index, total: lesson.exercises.length, onClose: _confirmQuit, onSave: canSave ? () => _save(exercise) : null, saved: _saved)),
          const SizedBox(height: 8),
          // ===== 2) the exercise, 3) the verdict sliding in over its bottom: the exercise area keeps its size, so
          // its sign videos (native views, costly to move) stay where they are =====
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scroll, padding: EdgeInsets.fromLTRB(16, 8, 16, result != null ? 140 : 8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                      transitionBuilder: (child, animation) {
                        final bool incoming = child.key == ValueKey(exercise.id);
                        return SlideTransition(position: Tween(begin: Offset(incoming ? 0.35 : -0.35, 0), end: Offset.zero).animate(animation), child: FadeTransition(opacity: animation, child: child));
                      },
                      child: KeyedSubtree(key: ValueKey(exercise.id), child: body)
                    )
                  )
                ),
                if (result != null)
                  Positioned(
                    left: 16, right: 16, bottom: 2,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(exercise.id), tween: Tween(begin: 0, end: 1), duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic,
                      builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child)),
                      child: LessonFeedbackBanner(isCorrect: result.isCorrect, correctAnswer: _correctText(exercise, result), explanation: result.explanation)
                    )
                  )
              ]
            )
          ),
          // ===== 4) button =====
          const SizedBox(height: 4),
          // gone at once on "Next question", then fades back in once the new exercise is in place
          AnimatedOpacity(
            opacity: _switching ? 0 : 1, duration: _switching ? Duration.zero : const Duration(milliseconds: 250), curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: _switching,
              child: Padding(
                padding: side,
                child: learn
                  ? LessonCheckButton(
                    checked: false, isCorrect: null, canCheck: true, busy: _busy, last: lastExercise, onCheck: () => _learnNext(exercise), onNext: _next,
                    label: loc.translate(_slide + 1 < exercise.options.length ? 'next' : (lastExercise ? 'continue' : 'next_question')),
                  )
                  : LessonCheckButton(checked: result != null, isCorrect: result?.isCorrect, canCheck: _answer != null, busy: _busy, last: lastExercise, onCheck: _check, onNext: _next)
              )
            )
          )
        ]
      )
    );
  }
}

import 'package:flutter/material.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_textbooks.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/buildLessonsTextbooks.dart';
import 'package:signlang/components/uiTextBooks/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../../../../screens/textbooks.dart';
import '../../nameTextbooks/nameTextbooks.dart';

import 'package:signlang/services/theme_service.dart';
import 'package:signlang/services/builtin_lesson_player.dart';
class AlphabetLessons extends StatefulWidget{
  const AlphabetLessons({super.key});

  @override
  State<AlphabetLessons> createState() => _AlphabetLessonsState();
}

class _AlphabetLessonsState extends State<AlphabetLessons> {
  bool _isLoading = true;
  static const String _id = '0';
  late int _learned;

  // total comes from the textbook data (alphabet → 'total': 30), same source BuildLessonsTextbooks uses
  int get _total {
    final items = LessonsTextbooksData(context: context).lessonsTextbooksItems;
    final item = items.firstWhere((e) => e['id'] == _id, orElse: () => const <String, dynamic>{'total': 0});
    return int.tryParse('${item['total']}') ?? 0;
  }

  double get _progress => _total == 0 ? 0 : _learned / _total;

  @override
  void initState(){ super.initState(); _initData(); }

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _recomputeLearned(); _learned = LessonProgress.instance.learnedOf(_id); }

  // =======================================================================
  LessonStatus _statusFor(int i) {
    final items = AlphabetLessonsData(context: context).alphabetLessonsItem;
    bool done(int k) => LessonProgress.instance.isCompleted(items[k]['id']);

    if (done(i)) return LessonStatus.passed;
    if (i == 0) return LessonStatus.opened;
    if (done(i - 1)) return LessonStatus.opened;
    return LessonStatus.locked;
  }

// =======================================================================
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) {setState(() {_isLoading = false;});} }
  Future<void> _handleRefresh() async { setState(() {_isLoading = true;}); await _initializeData(); }
  Future<void> _initializeData() async { final results = await Future.wait([AppLoading.ready()]); if (!mounted) return; setState(() { _isLoading = false; }); }

// =======================================================================
  void _completeLetter() { setState(() { if (_learned < _total) _learned++; LessonProgress.instance.setLearned(_id, _learned); }); }

  void _startLessons(int i) async {
    if (_statusFor(i) == LessonStatus.locked) return;
    final items = AlphabetLessonsData(context: context).alphabetLessonsItem;
    final id = items[i]['id'];
    // Exercises made in the dashboard are played from the server
    if (await BuiltinLessonPlayer.play(context, id)) {
      if (mounted) setState(() => _recomputeLearned());
      return;
    }
    // The alphabet lessons only exist in the dashboard now (their old screens were removed):
    // they need the internet and a logged-in account
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('lesson_needs_online')), behavior: SnackBarBehavior.floating));
  }

  void _recomputeLearned() {
    final items = AlphabetLessonsData(context: context).alphabetLessonsItem;
    int sum = 0;
    for (final item in items) { if (LessonProgress.instance.isCompleted(item['id'])) {sum += int.tryParse('${item['count']}') ?? 0; } }
    _learned = sum;
    LessonProgress.instance.setLearned(_id, _learned);
  }

  @override
  Widget build(BuildContext context) {
    final alphabetLessonsData = AlphabetLessonsData(context: context);
    final alphabetLessonsItem = alphabetLessonsData.storesByAlphabetLessons['0'] ?? [];
    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  // ======= 1 =======
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: AlphabetLessonsSkeleton.buildSkeleton()))
                else ...[
                  // ======= 2 =======
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== 1) back =====
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.arrow_back_outlined))
                          ),
                          const SizedBox(height: 16),
                          // ===== 2) text =====
                          Text(AppLocalizations.of(context)!.translate('alphabet'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                          Text(AppLocalizations.of(context)!.translate('daily_and_basic_alp'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[600]!))),
                          const SizedBox(height: 16),
                          // ===== 3) how many line =====
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
                              boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: Text('$_learned/$_total ${AppLocalizations.of(context)!.translate('letter_learned')}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
                                    Text("${(_progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppPalette.fg(Colors.blue[900]!)))
                                  ]
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(value: _progress, minHeight: 10, backgroundColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.3), valueColor: AlwaysStoppedAnimation(AppPalette.fg(Color(0xFF4A7FE0))))
                                )
                              ]
                            )
                          )
                        ]
                      )
                    )
                  ),
                  // ======= 3 =======
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== 1) text =====
                          Text(AppLocalizations.of(context)!.translate('lessons'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                          const SizedBox(height: 16),
                          // ===== 2) click to cards =====
                          Column(
                            children: List.generate(alphabetLessonsItem.length, (i) {
                              final lesson = Map<String, dynamic>.from(alphabetLessonsItem[i]);
                              // final id = lesson['id'];
                              // if (_learnedOverrides.containsKey(id)) {
                              //   lesson['learned'] = _learnedOverrides[id];
                              // }
                              lesson['status'] = _statusFor(i);
                              return GestureDetector(
                                onTap: _statusFor(i) == LessonStatus.locked ? null : () => _startLessons(i),
                                child: Padding(padding: const EdgeInsets.only(bottom: 16), child: BuildAllLessons.buildAllLessons(context, lesson))
                              );
                            })
                          ),
                          // lessons added in the dashboard after the app's own
                          ApiExtraLessons(slug: 'alphabet', builtInCount: alphabetLessonsItem.length)
                        ]
                      )
                    )
                  )
                ]
              ]
            )
          )
        )
      )
    );
  }
}
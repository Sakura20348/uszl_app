import 'package:flutter/material.dart';
import 'package:signlang/api/api_errors.dart';
import 'package:signlang/components/uiTextBooks/apiTextbooks/api_textbooks.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiTextBooks/group/alphabetLessons/alphabetLessons.dart';
import 'package:signlang/components/uiTextBooks/group/dilyLifeLessons/dailyLifeLessons.dart';
import 'package:signlang/components/uiTextBooks/group/familyLessons/familyLessons.dart';
import 'package:signlang/components/uiTextBooks/group/feelingLessons/feelingLessons.dart';
import 'package:signlang/components/uiTextBooks/group/foodLessons/foodLessons.dart';
import 'package:signlang/components/uiTextBooks/group/numberLessons/numberLessons.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/buildLessonsTextbooks.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'package:signlang/components/uiTextBooks/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../../../screens/textbooks.dart';

import 'package:signlang/services/theme_service.dart';
class AllLessons extends StatefulWidget{
  const AllLessons({super.key});

  @override
  State<AllLessons> createState() => _AllLessonsState();
}

class _AllLessonsState extends State<AllLessons> {
  bool _isLoading = true;

  @override
  void initState(){ super.initState(); _initData(); }

// =======================================================================
  LessonStatus _statusFor(int i) {
    final items = LessonsTextbooksData(context: context).lessonsTextbooksItems;

    int totalOf(int k) => int.tryParse('${items[k]['total']}') ?? 0;

    int learnedOf(int k) {
      final id = items[k]['id'];
      final saved = LessonProgress.instance.learnedOf(id);
      if (saved > 0) return saved;
      return int.tryParse('${items[k]['learned']}') ?? 0;
    }

    bool passed(int k) => totalOf(k) > 0 && learnedOf(k) >= totalOf(k);

    if (passed(i)) return LessonStatus.passed;
    if (i == 0) return LessonStatus.opened;
    if (passed(i - 1)) return LessonStatus.opened;
    return LessonStatus.locked;
  }

// =======================================================================
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initializeData() async { final results = await Future.wait([ AppLoading.ready() ]); if (!mounted) return; setState(() { _isLoading = false; }); }

// ================================ Button ==================================
  Future<void> _openLesson(int i) async {
    if (_statusFor(i) == LessonStatus.locked) return;

    final items = LessonsTextbooksData(context: context).lessonsTextbooksItems;
    final id = items[i]['id'];

    Widget? page;
    switch (id) {
      case '0': page = const AlphabetLessons(); break;
      case '1': page = const NumberLessons(); break;
      case '2': page = const FamilyLessons(); break;
      case '3': page = const FoodLessons(); break;
      case '4': page = const FeelingLessons(); break;
    }
    if (page != null) { Navigator.push(context, MaterialPageRoute(builder: (_) => page!)); return; }
    // no screens in the app for this textbook: its lessons come from the dashboard
    final slug = builtInTextbookSlugs[id];
    if (slug != null && await openServerTextbook(context, slug)) return;
    if (!mounted) return;
    if (id == '5') { Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyLifeLessons())); return; }
    showRedSnackBar(context, AppLocalizations.of(context)!.translate('section_unavailable'));
  }

// =======================================================================

  @override
  Widget build(BuildContext context) {
    final lessonsTextbooksData = LessonsTextbooksData(context: context);
    final lessonsTextbooksItems = lessonsTextbooksData.storesByLessonsTextbooks['0'] ?? [];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              slivers: [
                if(_isLoading)
                // ======= 1 =======
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: AllLessonsSkeleton.buildSkeleton()))
                else
                // ======= 2 =======
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== 1) back =====
                          GestureDetector(
                            onTap: () {if (Navigator.canPop(context)) {Navigator.pop(context);}},
                            child: Container(
                              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                              child: Icon(Icons.arrow_back_outlined),
                            )
                          ),
                          const SizedBox(height: 24),
                          // ===== 2) text =====
                          Text(AppLocalizations.of(context)!.translate('all_textbooks'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(AppLocalizations.of(context)!.translate('all_textbooks_sub'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
                          const SizedBox(height: 18),
                          // ===== 3) click to cards =====
                          Column(
                            children: List.generate(lessonsTextbooksItems.length, (i) {
                              final lesson = lessonsTextbooksItems[i];
                              lesson['status'] = _statusFor(i);

                              return GestureDetector(
                                onTap: _statusFor(i) == LessonStatus.locked ? null : () => _openLesson(i),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: BuildLessonsTextbooks.buildLessonTextbooks(context, lesson),
                                ),
                              );
                            }),
                          ),
                          // ===== 4) textbooks made in the dashboard =====
                          const ApiTextbookList(),
                        ],
                      ),
                    ),
                  )
              ],
            )
          )
        ),
      ),
    );
  }
}
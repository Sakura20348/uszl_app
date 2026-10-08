import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:signlang/components/uiTextBooks/group/foodLessons/foodLessons.dart';
import 'package:signlang/components/uiTextBooks/group/foodLessons/two/one.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'package:signlang/components/web/day/today.dart';
import 'package:signlang/services/statistics_service.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../web/loading/gradientLoading.dart';

import 'package:signlang/services/theme_service.dart';
class LessonsOverFoodTwo extends StatefulWidget{
  final String groupId;
  const LessonsOverFoodTwo({super.key, required this.groupId});

  @override
  State<LessonsOverFoodTwo> createState() => _LessonsOverFoodTwoState();
}

class _LessonsOverFoodTwoState extends State<LessonsOverFoodTwo> {
  bool _isLoading = true;
  bool get isDay => DateTime.now().weekday <= DateTime.daysPerWeek;

  int imolar = 0;
  int ballar = 0;

  int get natija => ((imolar / LessonProgress.maxImolar) * 100).round().clamp(0, 100);

  // value string per stat index
  String _statValue(int index) {
    final loc = AppLocalizations.of(context)!;
    switch (index) {
      case 0: return '$imolar ${loc.translate('pieces')}';
      case 1: return '$ballar';
      case 2: return '$natija%';
      default: return '';
    }
  }

  @override
  void initState() {
    super.initState();
    imolar = LessonProgress.instance.imolar;
    ballar = LessonProgress.instance.ballar;
    _initData();
  }

// =======================================================================
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _initializeData() async { final results = await Future.wait([AppLoading.ready()]); if (!mounted) return; setState(() { _isLoading = false; }); }

  void _syncLearned() {
    LessonProgress.instance.recomputeLearned(context);
  }

  Future<void> _handLeValidation() async {
    LessonProgress.instance.markCompleted(widget.groupId);
    _syncLearned();
    // Record 5 minutes of study time
    await StatisticsService.instance.addStudyTime(5);

    final shown = await StreakManager.alreadyShownToday();
    if (!mounted) return;

    if (!shown) {
      final result = await StreakManager.recordCompletion(); await StreakManager.markShownToday(); if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Today()));
    } else { Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const FoodLessons()), (route) => route.isFirst); }
  }

  void _handLeReload() {
    LessonProgress.instance.resetStats();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OneFood2()));
  }

  @override
  Widget build(BuildContext context){
    const String ImagePath = 'web/images/well_done.png';
    const String ImageReload = 'web/icons/reload.png';
    final AppLocalizations loc = AppLocalizations.of(context)!;

    final oneLessonsGreatData = OneLessonsGreatData(context: context);
    final oneLessonsGreatItem = oneLessonsGreatData.storeOneLessonsGreatItem['0'] ?? [];

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
              child: CustomScrollView(
                slivers: [
                  if(_isLoading)
                    SliverFillRemaining(hasScrollBody: false, child: Center(child: GradientLoading(size: 80, strokeWidth: 8)))
                  else
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 80),
                            // ===== 1) image =====
                            Image.asset(ImagePath, height: 254),
                            const SizedBox(height: 12),
                            // ===== 2) text =====
                            Align(
                              alignment: Alignment.topLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(loc.translate('lessons_over'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 5),
                                  Text(loc.translate('lessons_over_food'), style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15, color: AppPalette.fg(Colors.black).withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // ===== 3) how many ---
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: List.generate(oneLessonsGreatItem.length, (index) {
                                  return Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(child: _buildGreatItem(context, oneLessonsGreatItem[index], _statValue(index))),
                                        if (index < oneLessonsGreatItem.length - 1)
                                          _buildDividerVertical(),
                                      ],
                                    ),
                                  );
                                }),
                              )
                            ),
                            const Spacer(),
                            // ===== 4) button =====
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: _handLeValidation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                                  side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(loc.translate('next_lesson'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.fg(Colors.blue[900]!))),
                                    const SizedBox(width: 10), Icon(Icons.arrow_forward_outlined, color: AppPalette.fg(Colors.blue[900]!), size: 16)
                                  ]
                                )
                              )
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: _handLeReload,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.bg(Colors.grey).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                                  shadowColor: AppPalette.shadow(Colors.grey).withValues(alpha: 0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(ImageReload, color: AppPalette.fg(Colors.white), width: 16, height: 17), const SizedBox(width: 10),
                                    Text(loc.translate('next_lesson_sub'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.fg(Colors.white))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    )
                ],
              )
            ),
          ),
        ),
      ),
    );
  }

  // ======================== build ========================
  Widget _buildGreatItem(BuildContext context, Map<String, dynamic> item, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(item['image'], width: 30, height: 30, fit: BoxFit.contain), const SizedBox(height: 10),
        Text(item['title'], style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: AppPalette.fg(Colors.grey[600]!)), textAlign: TextAlign.center),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A))), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDividerVertical() {
    return Container(
      width: 1, height: 60, color: AppPalette.bg(Colors.black).withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

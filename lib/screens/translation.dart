import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/buildLessonsTextbooks.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/theme_service.dart';

import '../components/profile/nameProfile/nameProfileSheet.dart';
import '../components/uiTextBooks/skeleton/skeleton.dart';
import '../components/uiTranslation/group/gestureToText.dart';
import '../components/uiTranslation/group/speechToText.dart';
import '../components/uiTranslation/group/textToGesture.dart';
import '../components/uiTranslation/group/translator.dart';
import '../components/uiTranslation/group/transInfoSheet.dart';
import '../components/uiTranslation/nameTranslation/nameTrans.dart';
import '../components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import '../main.dart';
import 'textbooks.dart';
import '../services/app_loading.dart';

class Translation extends StatefulWidget{
  /// True while this tab is the one shown (the cards' lock is re-checked when it opens).
  final bool isActive;
  const Translation({super.key, this.isActive = true});

  @override
  State<Translation> createState() => _TranslationState();
}

class _TranslationState extends State<Translation>{
  int tabIndex = 2;
  bool _isLoading = true;

  late final achievementsData = AchievementsData(context: context);
  late final allSettingData = AllSettingsData(context: context);
  late final allSetting = allSettingData.storesByAllSettings['0'] ?? [];

  final Map<String, int> _learnedOverrides = {};

  @override
  void didUpdateWidget(Translation old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) setState(() {}); // a lesson may have been finished meanwhile
  }

  @override
  void initState(){
    super.initState(); _initData();
  }

  Future<void> _initializeData() async {
    await Future.wait([achievementsData.init(), AppLoading.ready()]);
    if (!mounted) return;
    setState(() { _isLoading = false; });
  }
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }

  List<Map<String, dynamic>> get itemsData => TransData(context: context).itemsData;

  // these modes open once the first textbook lesson is finished; the others aren't built yet
  static const Set<String> _readyModes = {'0', '1', '2', '3'};
  bool get _hasStartedLessons => LessonProgress.instance.completedCount > 0;

  LessonStatus _statusFor(int i) {
    final id = itemsData[i]['id'];
    return _readyModes.contains(id) && _hasStartedLessons ? LessonStatus.opened : LessonStatus.locked;
  }

  Future<void> _openTrans(int i) async {
    final id = itemsData[i]['id'];
    if (!_readyModes.contains(id)) {
      await TransInfoSheet.show(context, titleKey: 'section_unavailable', subKey: 'section_unavailable_sub');
      return;
    }
    if (!_hasStartedLessons) {
      await TransInfoSheet.show(
        context, titleKey: 'trans_locked_title', subKey: 'trans_locked_sub', buttonKey: 'go_to_lessons', icon: Icons.menu_book_rounded,
        onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainWrapper(initialTab: 0)), (route) => false),
      );
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => switch (id) {
      '1' => const TextToGesture(),
      '2' => const SpeechToTextPage(),
      '3' => const Translator(initialInput: TransMode.text, initialOutput: TransMode.voice),
      _ => const GestureToText(),
    }));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context){
    final c = AppColors.of(context);
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: c.surface,
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                if(_isLoading)
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: c.isDark ? Colors.white12 : Colors.grey[200]!, highlightColor: Color(0xFF42A5F5).withValues(alpha: 0.2), child: TextBooksSkeleton.buildSkeleton()))
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // === text ===
                          Text(loc.translate('translation_center'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)), const SizedBox(height: 6),
                          Text(loc.translate('translation_center_sub'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
                          const SizedBox(height: 18),
                          Column(
                            children: List.generate(itemsData.length, (i) {
                              final lesson = Map<String, dynamic>.from(itemsData[i]);
                              lesson['titleKey'] = loc.translate(lesson['titleKey']);
                              final id = lesson['id'];
                              if (_learnedOverrides.containsKey(id)) { lesson['learned'] = _learnedOverrides[id]; }
                              lesson['status'] = _statusFor(i);
                              return GestureDetector(
                                onTap: () => _openTrans(i),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: BuildTranslation.buildTrans(context, lesson)
                                )
                              );
                            })
                          )
                        ]
                      )
                    )
                  )
              ]
            )
          )
        )
      )
    );
  }
}
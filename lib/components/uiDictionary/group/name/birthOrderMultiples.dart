import 'package:flutter/material.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/nameStore.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFiftyEightResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFiftyFiveResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFiftyFourResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFiftyOneResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFiftyResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFiftySevenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFiftySixResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFiftyThreeResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFiftyTwoResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFortyEightResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFortyFourResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFortyNineResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFortyOneResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFortyResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyFortyTwoResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyNinetyFourResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyNinetyThreeResult.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/pageFamily.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../../skeleton/skeleton.dart';

import 'package:signlang/services/theme_service.dart';
class BirthOrderMultiples extends StatefulWidget{
  const BirthOrderMultiples({super.key});

  /// Word page for a list item id (also used by the dictionary's "Last seen").
  static Widget? pageFor(String id) => switch (id) {
    '0' => const GrownUpOneResult(), '1' => const AdultOneResult(), '2' => const ElderOneResult(), '3' => const YoungerOneResult(), '4' => const WidowOneResult(), '5' => const WidowerOneResult(),
    '6' => const ToBeBornOneResult(), '7' => const TallOneResult(), '8' => const LittleOneResult(), '9' => const ThickOneResult(), '10' => const IllOneResult(), '11' => const ThinOneResult(),
    '12' => const YoungOneResult(), '13' => const DeathOneResult(), '14' => const ToDieOneResult(),
    _ => null,
  };

  @override
  State<BirthOrderMultiples> createState() => _BirthOrderMultiplesState();
}

class _BirthOrderMultiplesState extends State<BirthOrderMultiples> {
  bool _isLoading = true;

  late final List<Map<String, dynamic>> items;

// =======================================================================
  @override
  void didChangeDependencies() { super.didChangeDependencies(); items = BirthOrderMultiplesData(context: context).famItem; }

  @override
  void initState() { super.initState(); _initData(); }

  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initializeData() async { final results = await Future.wait([ AppLoading.ready() ]); if (!mounted) return; setState(() { _isLoading = false; }); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) { return notification.depth == 0; },
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: AllPhrasesSkeleton.buildSkeleton()))
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.arrow_back_outlined),
                            )
                          ),
                          const SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.translate('words_sub_5'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                          const SizedBox(height: 16),
                          Column(children: List.generate(items.length, (index) => _buildFamily(items[index])))
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
  Widget _buildFamily(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _openLessonsAll(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
          boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)]
        ),
        child: Row(
          children: [
            Container(
              height: 56, width: 56, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(16)),
              child: Center(child: Image.asset(item['image'], width: 30, height: 30, color: AppPalette.fg(Colors.blue), errorBuilder: (_, __, ___) => Icon(Icons.person, size: 35, color: AppPalette.fg(Colors.blue)))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  Text(item['title_sub'] ?? '', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right)
            )
          ]
        )
      )
    );
  }

  // =======================================================================
  Future<void> _openLessonsAll(Map<String, dynamic> item) async {
    final id = item['id'];
    final page = BirthOrderMultiples.pageFor(id);

    if (page == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    // watched: show it first in the dictionary's "Last seen"
    await LastSeenStore.instance.add(item['title'], item['image'] ?? '', source: 'BirthOrderMultiples', id: id);
    if (mounted) setState(() {});
  }
}
import 'package:flutter/material.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/nameStore.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodEightResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodEightyFourResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodEightyOneResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodEightyResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodEightyThreeResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodEightyTwoResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodElevenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFifteenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFiveResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFourResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFourteenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodNineResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodOneResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodSevenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodSeventyEightResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodSeventyNineResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodSeventySevenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodSixResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodSixteenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodTenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodThirteenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodThreeResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodTwelveResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodTwoResult.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/pageFood.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../../skeleton/skeleton.dart';

import 'package:signlang/services/theme_service.dart';
class SomeFood extends StatefulWidget{
  const SomeFood({super.key});

  /// Word page for a list item id (also used by the dictionary's "Last seen").
  static Widget? pageFor(String id) => switch (id) {
    '0' => const FoodOneResult(), '1' => const SoupOneResult(), '2' => const PilafOneResult(), '3' => const RicePilafOneResult(),
    '4' => const SamosaOneResult(), '5' => const SteamedDumplingsOneResult(), '6' => const DumplingsOneResult(), '7' => const KebabOneResult(),
    '8' => const PelmeniOneResult(), '9' => const BiscuitOneResult(), '10' => const FreshOneResult(), '11' => const FriedEggsOneResult(),
    '12' => const WaterOneResult(), '13' => const CoffeeOneResult(), '14' => const TeaOneResult(), '15' => const SweetTeaOneResult(),
    '16' => const ChampagneOneResult(), '17' => const MeatOneResult(), '18' => const EggOneResult(), '19' => const RissoleOneResult(),
    '20' => const SausagesOneResult(), '21' => const HerringOneResult(), '22' => const CakeOneResult(), '23' => const CannedFoodOneResult(),
    '24' => const TenderFoodOneResult(),
    _ => null,
  };

  @override
  State<SomeFood> createState() => _SomeFoodState();
}

class _SomeFoodState extends State<SomeFood> {
  bool _isLoading = true;

  late final List<Map<String, dynamic>> items;

// =======================================================================
  @override
  void didChangeDependencies() { super.didChangeDependencies(); items = FoodData(context: context).foodItem; }

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
                          Text(AppLocalizations.of(context)!.translate('food'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
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
    final page = SomeFood.pageFor(id);

    if (page == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    // watched: show it first in the dictionary's "Last seen"
    await LastSeenStore.instance.add(item['title'], item['image'] ?? '', source: 'SomeFood', id: id);
    if (mounted) setState(() {});
  }
}
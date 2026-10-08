import 'package:flutter/material.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/nameStore.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFiftyResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortyEightResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortyFiveResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortyFourResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortyNineResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortyOneResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortyResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortySevenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortySixResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortyThreeResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodFortyTwoResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodSixtyFiveResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodThirtyEightResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodThirtyNineResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodThirtySevenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/food/foodThirtySixResult.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/pageFood.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../../skeleton/skeleton.dart';

import 'package:signlang/services/theme_service.dart';
class SomeVegetables extends StatefulWidget{
  const SomeVegetables({super.key});

  /// Word page for a list item id (also used by the dictionary's "Last seen").
  static Widget? pageFor(String id) => switch (id) {
    '0' => const VegetablesOneResult(), '1' => const OnionOneResult(), '2' => const PotatoOneResult(), '3' => const CarrotOneResult(), '4' => const TomatoOneResult(),
    '5' => const CucumberOneResult(), '6' => const GarlicOneResult(), '7' => const PepperOneResult(), '8' => const EggplantOneResult(), '9' => const PumpkinOneResult(),
    '10' => const CabbageOneResult(), '11' => const BeetrootOneResult(), '12' => const SmallRedRadishOneResult(), '13' => const BlackRadishOneResult(), '14' => const CornOneResult(),
    '15' => const MushroomOneResult(),
    _ => null,
  };

  @override
  State<SomeVegetables> createState() => _SomeVegetablesState();
}

class _SomeVegetablesState extends State<SomeVegetables> {
  bool _isLoading = true;

  late final List<Map<String, dynamic>> items;

// =======================================================================
  @override
  void didChangeDependencies() { super.didChangeDependencies(); items = VegetablesData(context: context).vegetablesItem; }

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
                          Text(AppLocalizations.of(context)!.translate('vegetables'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                          const SizedBox(height: 16), Column(children: List.generate(items.length, (index) => _buildFamily(items[index])))
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
    final page = SomeVegetables.pageFor(id);

    if (page == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    // watched: show it first in the dictionary's "Last seen"
    await LastSeenStore.instance.add(item['title'], item['image'] ?? '', source: 'SomeVegetables', id: id);
    if (mounted) setState(() {});
  }
}
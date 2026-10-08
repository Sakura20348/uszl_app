import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiDictionary/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';

import '../../nameDictionary/nameDictionary.dart';

import 'package:signlang/services/theme_service.dart';
class AllPhrases extends StatefulWidget{
  const AllPhrases({super.key});

  @override
  State<AllPhrases> createState() => _AllPhrasesState();
}

class _AllPhrasesState extends State<AllPhrases> {
  bool _isLoading = true;

  late final StoresDictionaryCardsData storesData;
  late final List<Map<String, dynamic>> items;

// =======================================================================
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    storesData = StoresDictionaryCardsData(context: context);
    items = (storesData.storesDictionaryCardsByCategory['0'] ?? []).where((s) => s['id'] != '0').toList();
  }

  @override
  void initState() { super.initState(); _initData(); }

  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initializeData() async { final results = await Future.wait([AppLoading.ready()]); if (!mounted) return; setState(() { _isLoading = false; }); }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) { return notification.depth == 0; },
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  // ======= 1 =======
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
                          Text(AppLocalizations.of(context)!.translate('all_phrases'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                          const SizedBox(height: 16),
                          Column(children: List.generate(items.length, (index) => _categoryColumn(items[index], '0')))
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
  Widget _categoryColumn(Map<String, dynamic> item, String categoryId) {
    return GestureDetector(
      onTap: () => _openLessonsAll(categoryId, item),
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
              child: const Icon(Icons.chevron_right),
            )
          ],
        ),
      ),
    );
  }

  // =======================================================================
  Future<void> _openLessonsAll(String categoryId, Map<String, dynamic> item) async {
    final id = item['id'];
    Widget? page;

    if (categoryId == '0') {
      page = switch (id) {
      // '0' => const AlphabetResult(),
      // '1' => const FamilyResult(),
      // '2' => const AlphabetResult(),
      // '3' => const AlphabetResult(),
        _ => null,
      };
    }

    if (page == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    if (mounted) setState(() {});
  }
}
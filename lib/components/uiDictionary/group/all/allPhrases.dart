import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiDictionary/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiDictionary/server/category_icon.dart';

import 'package:signlang/services/theme_service.dart';
/// Every dictionary category from the dashboard. Tapping one closes this page with its index,
/// and the dictionary opens that category's signs.
class AllPhrases extends StatefulWidget{
  final List<ApiCategory> categories;
  const AllPhrases({super.key, required this.categories});

  @override
  State<AllPhrases> createState() => _AllPhrasesState();
}

class _AllPhrasesState extends State<AllPhrases> {
  bool _isLoading = true;

// =======================================================================
  @override
  void initState() { super.initState(); _initData(); }

  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { await _initializeData(); }
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
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.arrow_back_outlined))
                          ),
                          const SizedBox(height: 16), Text(AppLocalizations.of(context)!.translate('all_phrases'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                          const SizedBox(height: 16), Column(children: List.generate(widget.categories.length, (index) => _categoryColumn(index)))
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

  Widget _categoryColumn(int index) {
    final cat = widget.categories[index];
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final unit = lang == 'uz' && (cat.unitLabel?.isNotEmpty ?? false) ? cat.unitLabel! : loc.translate('dict_signs_count');
    return GestureDetector(
      onTap: () => Navigator.pop(context, index),
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
              child: Center(child: CategoryIcon(cat.icon ?? CategoryIcon.bySlug[cat.slug] ?? CategoryIcon.fallback, size: 30, color: AppPalette.fg(Colors.blue))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.nameFor(lang), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  Text('${cat.signCount} $unit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!)))
                ]
              )
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

}
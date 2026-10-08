import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/profile/group/achievement/awardsInfo.dart';
import 'package:signlang/components/profile/nameProfile/nameProfileSheet.dart';
import 'package:signlang/components/profile/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/achievement_service.dart';

import 'package:signlang/services/theme_service.dart';
class AllAchievements extends StatefulWidget{
  const AllAchievements({super.key});

  @override
  State<AllAchievements> createState() => _AllAchievementsState();
}

class _AllAchievementsState extends State<AllAchievements> {
  bool _isLoading = true;
  late final achievementsData = AchievementsData(context: context);

// =======================================================================
  @override
  void initState(){ super.initState(); _initializeData(); }

// =======================================================================
  Future<void> _initializeData() async {
    await achievementsData.init();
    await AppLoading.ready();
    if (!mounted) return;
    setState(() { _isLoading = false; });
    _announceUnlocked(achievementsData.justUnlocked);
  }

  // tell the person which achievements just opened
  void _announceUnlocked(List<String> ids) {
    if (ids.isEmpty) return;
    final loc = AppLocalizations.of(context)!;
    final names = achievementsData.achievementsItems.where((e) => ids.contains(e['id'])).map((e) => e['titleKey']).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: AppPalette.bg(const Color(0xFF2E7D32)),
      content: Row(children: [const Icon(Icons.emoji_events, color: Colors.amber), const SizedBox(width: 10), Expanded(child: Text(loc.translate('ach_unlocked_msg').replaceAll('{name}', names), style: const TextStyle(color: Colors.white)))]),
    ));
  }

  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }

  Future<void> _handleInfo(int index, Map<String, dynamic> item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: AwardsInfo(item: item),
      ),
    );

    // once seen, a just-opened achievement is no longer "New!"
    if (item['isNew'] == true) await AchievementService.instance.markSeen(item['id']);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context){
    final AppLocalizations loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withOpacity(0.2), child: AllAchievementsSkeleton.buildSkeleton()))
                else ... [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.arrow_back_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.translate('achievements'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(loc.translate('achievements_sub'), style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15, color: AppPalette.fg(Colors.grey[700]!)))
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final items = achievementsData.achievementsItems;
                          if (index >= items.length) return null;
                          final item = items[index];
                          final bool unlocked = item['unlocked'] ?? false;
                          final bool isNew = item['isNew'] ?? false;
                          final int progress = item['progress'] ?? 0, target = item['target'] ?? 1;
                          final List<double> matrix = [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0,      0,      0,      0.6, 0];
                          
                          return GestureDetector(
                            onTap: () => _handleInfo(index, item),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: unlocked ? AppPalette.bg(Colors.white).withOpacity(0.5) : AppPalette.bg(Colors.grey).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: unlocked ? AppPalette.border(Colors.white) : AppPalette.border(Colors.white).withOpacity(0.2)),
                                boxShadow: unlocked ? [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 6))] : null
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ColorFiltered(
                                    colorFilter: unlocked ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply) : ColorFilter.matrix(matrix),
                                    child: Image.asset(
                                      item['image'] as String, height: 40, width: 40, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.stars, size: 40, color: AppPalette.fg(Colors.grey)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item['titleKey'] as String, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: unlocked ? AppPalette.fg(Color(0xFF0F172A)) : AppPalette.fg(Colors.grey)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['subKey'] as String, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: unlocked ? AppPalette.fg(Colors.grey[600]!) : AppPalette.fg(Colors.grey[600]!).withOpacity(0.8)),
                                  ),
                                  const SizedBox(height: 8),
                                  // status: "New!" / "Opened" once done, otherwise "Closed" with how far the person is
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: (unlocked ? (isNew ? AppPalette.bg(Colors.amber) : AppPalette.bg(Colors.green)) : AppPalette.bg(Colors.grey)).withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(unlocked ? (isNew ? Icons.auto_awesome : Icons.lock_open) : Icons.lock, size: 13, color: unlocked ? (isNew ? AppPalette.fg(Colors.orange[900]!) : AppPalette.fg(Colors.green[800]!)) : AppPalette.fg(Colors.grey[700]!)),
                                        const SizedBox(width: 4),
                                        Text(
                                          unlocked ? loc.translate(isNew ? 'ach_new' : 'opened') : '${loc.translate('locked')} · $progress/$target',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: unlocked ? (isNew ? AppPalette.fg(Colors.orange[900]!) : AppPalette.fg(Colors.green[800]!)) : AppPalette.fg(Colors.grey[700]!)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: achievementsData.achievementsItems.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30))
                ]
              ],
            )
          )
        ),
      ),
    );
  }
}

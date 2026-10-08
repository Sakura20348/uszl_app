import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiTextBooks/group/familyLessons/two/one.dart';
import 'package:signlang/components/uiTextBooks/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class ChildAndBoy extends StatefulWidget {
  const ChildAndBoy({super.key});

  @override
  State<ChildAndBoy> createState() => _ChildAndBoyState();
}

class _ChildAndBoyState extends State<ChildAndBoy> {
  bool _isLoading = true;

  @override
  void initState(){ super.initState(); _initData(); }

// =======================================================================
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { setState(() {_isLoading = true;}); await _initializeData(); }
  Future<void> _initializeData() async { final results = await Future.wait([AppLoading.ready()]); if (!mounted) return; setState(() { _isLoading = false; }); }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                if (_isLoading)
                // ======= 1 =======
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: StartOneLessonsSkeleton.buildSkeleton()))
                else
                // ======= 2 =======
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                              child: Icon(Icons.arrow_back_outlined),
                            )
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
                              boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
                            ),
                            child: Center(child: Image.asset('web/images/plus_sign.png', width: 183, height: 171)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${loc.translate('child')} - ${loc.translate('boy')} ${loc.translate('words')}',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)
                          ),
                          Text(loc.translate('words_sub'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[600]!))),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
                              boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
                            ),
                            child: Row(
                              children: [
                                _stat('web/icons/time.png', loc.translate('duration'), '5 ${loc.translate('time')}'), _divider(),
                                _stat('web/icons/level.png', loc.translate('level'), loc.translate('medium')), _divider(),
                                _stat('web/icons/hand.png', loc.translate('gesture'), '10 ${loc.translate('pieces')}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppPalette.bg(Color(0xFFFFCC80)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFFFC107)).withValues(alpha: 0.2)),
                              boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFFFFCC80)).withValues(alpha: 0.9), blurRadius: 15)]
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFFFF176)).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.yellow)), borderRadius: BorderRadius.circular(15)),
                                  child: Image.asset('web/icons/info_yellow.png', width: 28, height: 28, color: AppPalette.fg(Colors.orange)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(loc.translate('what_learn'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 4),
                                      Text(loc.translate('what_learn_sub_famTwo'), style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14))
                                    ]
                                  )
                                )
                              ]
                            )
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity, height: 56,
                            child: ElevatedButton(
                              onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (_) => const OneWords2()));},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                                side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: Text(AppLocalizations.of(context)!.translate('start_lesson'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.white))),
                            ),
                          ),
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

  Widget _stat(String imagePath, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Image.asset(imagePath, width: 22, height: 22, color: AppPalette.fg(Colors.blue[800]!)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, color: AppPalette.fg(Colors.grey[700]!))),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 60, color: AppPalette.bg(Colors.grey.shade300));
}
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyThirtyOneResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyTwentyNineResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyTwentySevenResult.dart';
import 'package:signlang/components/uiDictionary/group/result/family/familyTwentySixResult.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/nameResult.dart';
import 'package:video_player/video_player.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';
import '../../../../web/download/download.dart';
import '../../../../web/saved/saved.dart';
import '../../../skeleton/skeleton.dart';

import 'package:signlang/services/theme_service.dart';
class DivorceOneResult extends StatefulWidget {
  const DivorceOneResult({super.key});

  @override
  State<DivorceOneResult> createState() => _DivorceOneResultState();
}

class _DivorceOneResultState extends State<DivorceOneResult> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = true;
  double _currentSpeed = 1.0;

  @override
  void initState(){ super.initState(); _initData(); _initializePlayer(); }

// =======================================================================
// name things
// =======================================================================
  late final questionCardsData = QuestionCardsDivorceData(context: context).divorceItems;
  late final relatedGesturesItem = RelatedDivorceData(context: context).relatedDivorceItem;

// =======================================================================
  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.asset(''); // divorce
    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.play();
      setState(() => _isVideoInitialized = true);
    } catch (e) { debugPrint("Video init error: $e"); }
  }

  Future<void> _initializeData() async { await Future.wait([ AppLoading.ready(), ]); if (!mounted) return; setState(() { _isLoading = false; }); }
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }

// =======================================================================
  void _onInfoQuestion() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppPalette.border(Colors.white), width: 1)),
        elevation: 1, backgroundColor: AppPalette.bg(Colors.white).withValues(alpha: 0.7), shadowColor: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9),
        title: Text('${AppLocalizations.of(context)!.translate('what_family_question')}?', style: TextStyle(fontWeight: FontWeight.w700, color: AppPalette.fg(Color(0xFF0F172A)))),
        content: Text(AppLocalizations.of(context)!.translate('what_family_question_sub'), style: TextStyle(color: AppPalette.fg(Colors.grey[800]!), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.translate('ok'), style: TextStyle(color: AppPalette.fg(Colors.black), fontWeight: FontWeight.w600, fontSize: 15))
          )
        ]
      )
    );
  }

  Future<void> _openLessonsAll(Map<String, dynamic> w) async {
    final id = w['id'];
    Widget? page;
    page = switch (id) {
      '0' => const MarriageOneResult(), '1' => const TeenagerOneResult(),
      '2' => const GenerationOneResult(), '3' => const BrideOneResult(),
      _ => null,
    };

    if (page == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
    if (mounted) setState(() {});
  }

  void _showQuitDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppPalette.border(Colors.white), width: 1)), elevation: 15, backgroundColor: AppPalette.bg(Colors.white).withValues(alpha: 0.7),
        shadowColor: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), title: Text(loc.translate('quit_lesson'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        content: Text(loc.translate('quit_lesson_sub'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.grey[800]!))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.translate('cancel'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.grey[700]!), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(dialogContext); Navigator.pushAndRemoveUntil(context, _slideLeftRoute(const MainWrapper(initialTab: 1)), (route) => false); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.bg(Color(0xFFEF9A9A)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Color(0xFFB71C1C)).withOpacity(0.9),
              side: BorderSide(width: 1, color: AppPalette.border(Color(0xFFB71C1C)).withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            ),
            child: Text(loc.translate('quit'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.red[900]!), fontWeight: FontWeight.w600)),
          )
        ]
      )
    );
  }

  Route _slideLeftRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: const Offset(-1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context){
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false, onPopInvokedWithResult: (didPop, result) { if (didPop) return; _showQuitDialog(); },
      child: Scaffold(
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
                    SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: ResultLessonsSkeleton.buildSkeleton()))
                  else
                  // ======= 2 =======
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== 1) back, download and save =====
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: _showQuitDialog,
                                    child: Container(
                                      width: 46, height: 46, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                                      child: Icon(Icons.close, color: AppPalette.fg(Color(0xFF334155))),
                                    )
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                        onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const Download())); },
                                        child: Container(width: 46, height: 46, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.download)),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const Saved())); },
                                        child: Container(width: 46, height: 46, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.bookmark)),
                                      )
                                    ]
                                  )
                                ]
                              )
                            ),
                            const SizedBox(height: 18),
                            // ===== 2) video =====
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity, height: MediaQuery.of(context).size.height * 0.28, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(24)), clipBehavior: Clip.antiAlias,
                                    child: _isVideoInitialized ? AspectRatio(aspectRatio: _videoController.value.aspectRatio, child: VideoPlayer(_videoController)) : const Center(child: CircularProgressIndicator()),
                                  ),
                                  Positioned(
                                    top: 18, right: 20,
                                    child: GestureDetector(
                                      onTap: _onInfoQuestion,
                                      child: Container(
                                        width: 46, height: 46, padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.8), borderRadius: BorderRadius.circular(15), border: Border.all(width: 1, color: AppPalette.border(Colors.black).withOpacity(0.2))),
                                        child: Image.asset('web/icons/info_yellow.png', color: AppPalette.fg(Colors.grey)),
                                      )
                                    )
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // ===== 3) cards =====
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildVideoAction(Icons.refresh, loc.translate('again'), () => _videoController.seekTo(Duration.zero)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton2<double>(
                                        customButton: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                          decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withOpacity(0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withOpacity(0.9), blurRadius: 12)]),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.speed, size: 16, color: AppPalette.fg(Colors.black54)),
                                              const SizedBox(width: 6),
                                              Text("${_currentSpeed}x", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black))),
                                            ],
                                          ),
                                        ),
                                        items: [0.5, 1.0, 1.5].map<DropdownMenuItem<double>>((double speed) {
                                          final WeightData = (_currentSpeed - speed).abs() < 0.01 ? FontWeight.bold : FontWeight.normal;
                                          final Color isColor = (_currentSpeed - speed).abs() < 0.01 ? AppPalette.auto(Color(0xFF4A7FD0)) : AppPalette.auto(Colors.black87);
                                          return DropdownMenuItem<double>(value: speed, child: Center(child: Text("${speed}x", style: TextStyle(fontSize: 15, fontWeight: WeightData, color: isColor))));
                                        }).toList(),
                                        value: _currentSpeed,
                                        onChanged: (double? newSpeed) { if (newSpeed != null) { setState(() { _currentSpeed = newSpeed; }); if (_isVideoInitialized) { _videoController.setPlaybackSpeed(_currentSpeed); } } },
                                        dropdownStyleData: DropdownStyleData(width: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppPalette.bg(Colors.white)), offset: const Offset(0, -8)),
                                        menuItemStyleData: const MenuItemStyleData(height: 38, padding: EdgeInsets.symmetric(horizontal: 14)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _buildVideoAction(Icons.call_made, loc.translate('corner'), () {}),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // ===== 4) text =====
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loc.translate('divorce'), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
                                  Text(loc.translate('divorce_phrases'), style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15, color: AppPalette.fg(Colors.grey[700]!)))
                                ]
                              )
                            ),
                            const SizedBox(height: 16),
                            // ===== 5) cards things =====
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(children: List.generate(questionCardsData.length, (index) { return Padding(padding: const EdgeInsets.only(bottom: 16), child: _buildCardsData(questionCardsData[index])); })),
                            ),
                            const SizedBox(height: 16),
                            // ===== 6) cards example =====
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                width: double.infinity, padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFBBDEFB)).withOpacity(0.9), border: Border.all(width: 1.5, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 64, height: 64, padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.9), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
                                            child: Image.asset('', errorBuilder: (c, e, s) => Icon(Icons.person, size: 30, color: AppPalette.fg(Colors.blue)))
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(loc.translate('example_sentence'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                                                Text(loc.translate('example_sentence_divorce'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!)))
                                              ]
                                            )
                                          )
                                        ]
                                      )
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 46, height: 46, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.9), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
                                      child: Center(
                                        child: Container(
                                          height: 20, width: 20, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFF4A7FD0)), shape: BoxShape.circle),
                                          child: Icon(Icons.play_arrow, color: AppPalette.fg(Colors.white), size: 14)
                                        )
                                      )
                                    )
                                  ]
                                )
                              )
                            ),
                            const SizedBox(height: 16),
                            // ===== 7) text =====
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(loc.translate('related_gestures'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24))),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 150,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                                itemCount: relatedGesturesItem.length, itemBuilder: (_, index) => _relatedCard( relatedGesturesItem[index] )
                              )
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
      )
    );
  }

  // ======================== build ========================
  Widget _buildVideoAction(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withOpacity(0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withOpacity(0.8), blurRadius: 12)]),
        child: Row(children: [Icon(icon, size: 16, color: AppPalette.fg(Colors.black54)), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))])
      )
    );
  }

  Widget _buildCardsData(Map<String, dynamic> w){
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFBBDEFB)).withOpacity(0.9), border: Border.all(width: 1.5, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 50, height: 50, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.9), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
            child: Image.asset(w['image'], errorBuilder: (c, e, s) => const Icon(Icons.store)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w['word'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                Text(w['wordSub'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!)))
              ]
            )
          )
        ]
      )
    );
  }

  Widget _relatedCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _openLessonsAll(item),
      child: Container(
        width: 150, margin: const EdgeInsets.only(right: 6, left: 6),
        decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFBBDEFB)).withValues(alpha: 0.7), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            // character image
            Positioned.fill(top: 15, child: ClipRRect(child: Image.asset(item['image'], errorBuilder: (_, __, ___) => Icon(Icons.person, size: 60, color: AppPalette.fg(Colors.blue))))),
            // play button top-right
            Positioned(
              top: 10, right: 10,
              child: Container(
                height: 35, width: 35, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.3), shape: BoxShape.circle),
                child: Center(child: Container(height: 20, width: 20, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFF4A7FD0)), shape: BoxShape.circle), child: Icon(Icons.play_arrow, color: AppPalette.fg(Colors.white), size: 18))),
              ),
            ),
            // word label bottom
            Positioned(
              left: 10, right: 10, bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.white).withValues(alpha: 0.9), blurRadius: 15)]),
                child: Center(child: Text(item['word'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))))
              )
            )
          ]
        )
      )
    );
  }
}
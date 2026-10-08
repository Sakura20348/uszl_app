import 'dart:async';
import 'package:signlang/services/app_loading.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:signlang/components/uiTextBooks/group/foodLessons/foodOnboardingProgress.dart';
import 'package:signlang/components/uiTextBooks/group/foodLessons/four/two.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks2.dart';
import 'package:video_player/video_player.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../web/loading/bookLoading.dart';

import 'package:signlang/services/theme_service.dart';
import 'package:signlang/components/uiTextBooks/lessonCarouselWidgets.dart';
class OneFood4 extends StatefulWidget{
  const OneFood4({super.key});

  @override
  State<OneFood4> createState() => _OneFood4State();
}

class _OneFood4State extends State<OneFood4> {
  bool _isLoading = true;
  double _currentSpeed = 1.0;

  final CarouselSliderController _carouselController = CarouselSliderController();
  int _current = 0;

  List<dynamic> items = [];
  List<String> _slides = [];
  int _total = 0;
  bool _isInitialized = false;

  @override
  void initState() { super.initState(); _initData(); }

  @override
  void dispose() { _videosDisposed = true; _videoSwitchTimer?.cancel(); for (final c in _controllers.values) { c.dispose(); } _controllers.clear(); super.dispose(); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      items = FruitAndPomegranateData(context: context).item;
      _slides = List.generate(items.length, (i) => 'Slide ${i + 1}');
      _total = items.length;

      if (items.isNotEmpty) { final Map<String, dynamic> firstItem = items[0] as Map<String, dynamic>; _initializePlayer(0, firstItem); }
      _isInitialized = true;
    }
  }

  void _handleNext() {
    if (_current < _total - 1) {
      _carouselController.nextPage();
    } else { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TwoFood4())); }
  }

// =======================================================================
  // One controller per slide. The active slide and its neighbours are kept
  // initialized, so swiping shows the next video immediately.
  final Map<int, VideoPlayerController> _controllers = {};
  final Set<int> _failedVideos = {};
  int _activeVideo = 0;
  bool _videosDisposed = false;

  Timer? _videoSwitchTimer;

  // onPageChanged fires mid-swipe; starting decoders then drops frames, so wait until the carousel settles.
  void _scheduleVideoChange(int index) {
    _videoSwitchTimer?.cancel();
    _videoSwitchTimer = Timer(const Duration(milliseconds: 320), () { if (!_videosDisposed) _changeVideo(index); });
  }

  Future<void> _changeVideo(int index) async {
    _activeVideo = index;
    _controllers.forEach((i, c) { if (i != index && c.value.isInitialized) c.pause(); });
    final active = _controllers[index];
    if (active != null && active.value.isInitialized) { active.seekTo(Duration.zero); active.play(); }

    // Free controllers far from the current slide (hardware decoders are limited).
    final far = _controllers.keys.where((i) => (i - index).abs() > 1).toList();
    if (far.isNotEmpty) {
      final old = [for (final i in far) _controllers.remove(i)!];
      if (mounted) setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) { for (final c in old) { c.dispose(); } });
    }

    await _loadVideo(index);
    // Preload neighbours one at a time, after the active video is playing.
    for (final n in [index + 1, index - 1]) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_videosDisposed || _activeVideo != index) return;
      if (n >= 0 && n < items.length) await _loadVideo(n);
    }
  }

  Future<void> _initializePlayer(int index, Map<String, dynamic> item) => _changeVideo(index);

  String _videoAsset(int index) {
    final rawVideo = (items[index] as Map<String, dynamic>)['video'];
    if (rawVideo is List && rawVideo.isNotEmpty) { return (index >= 0 && index < rawVideo.length) ? rawVideo[index].toString() : rawVideo[0].toString(); }
    if (rawVideo is String) return rawVideo;
    return '';
  }

  Future<void> _loadVideo(int index) async {
    if (_controllers.containsKey(index) || _failedVideos.contains(index)) return;
    final String assetPath = _videoAsset(index);
    if (assetPath.isEmpty) { if (mounted) setState(() => _failedVideos.add(index)); return; }

    final controller = VideoPlayerController.asset(assetPath);
    _controllers[index] = controller;
    try {
      await controller.initialize();
      // Dropped while loading (page closed or slide scrolled far away).
      if (_videosDisposed || _controllers[index] != controller) { await controller.dispose(); return; }
      await controller.setPlaybackSpeed(_currentSpeed);
      await controller.setLooping(true);
      if (index == _activeVideo) await controller.play();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Video init error: $e");
      if (_controllers[index] == controller) _controllers.remove(index);
      await controller.dispose();
      if (mounted) setState(() => _failedVideos.add(index));
    }
  }

  Widget _slideVideo(int i, Widget Function(VideoPlayerController c) player, Widget loading) {
    final c = _controllers[i];
    if (c != null && c.value.isInitialized) return player(c);
    if (_failedVideos.contains(i)) return const LessonVideoUnavailable();
    return loading;
  }

  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initializeData() async { await Future.wait([AppLoading.ready()]); if (!mounted) return; setState(() { _isLoading = false; }); }

  @override
  Widget build(BuildContext context){
    final AppLocalizations loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) { return notification.depth == 0; },
            child: CustomScrollView(
              slivers: [
                if(_isLoading)
                  const SliverFillRemaining(hasScrollBody: false, child: Center(child: BookLoader(label: 'Loading')))
                else
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== 1) back =====
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                                child: const Icon(Icons.arrow_back_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // ===== 2) progress text and line =====
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('1/20', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
                                  const SizedBox(height: 4),const FoodOnboardingProgress(currentStep: 0)
                                ]
                              )
                            )
                          ),
                          // ===== 3) carouselSlider =====
                          Container(
                            margin: const EdgeInsetsGeometry.symmetric(vertical: 16),
                            child: CarouselSlider(
                              carouselController: _carouselController,
                              options: CarouselOptions(height: 460, autoPlay: false, enlargeCenterPage: true, viewportFraction: 0.92, onPageChanged: (index, reason) { setState(() => _current = index); _scheduleVideoChange(index); }),
                              items: _slides.asMap().entries.map((entry) {
                                final int i = entry.key;
                                final String slideTitle = (items.isNotEmpty && i < items.length) ? (items[i]['title'] ?? '') : '';
                                final String slideTitleSub = (items.isNotEmpty && i < items.length) ? (items[i]['title_sub'] ?? '') : '';

                                return RepaintBoundary(child: Container(
                                  margin: const EdgeInsets.all(6), padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
                                    boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Video Box
                                      Container(
                                        width: double.infinity, height: 210, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(20)), clipBehavior: Clip.antiAlias,
                                        child: _slideVideo(i, (c) => AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)), const Center(child: CircularProgressIndicator())),
                                      ),
                                      const SizedBox(height: 12),
                                      // Controls Action Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildVideoAction(Icons.refresh, loc.translate('again'), () { _controllers[_current]?.seekTo(Duration.zero); }),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton2<double>(
                                                customButton: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                                  decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.9), blurRadius: 12)]),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.speed, size: 16, color: AppPalette.fg(Colors.black54)), const SizedBox(width: 6),
                                                      Text("${_currentSpeed}x", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black)))
                                                    ]
                                                  )
                                                ),
                                                items: [0.5, 1.0, 1.5].map<DropdownMenuItem<double>>((double speed) {
                                                  final isWeight = (_currentSpeed - speed).abs() < 0.01 ? FontWeight.bold : FontWeight.normal;
                                                  final Color isColor = (_currentSpeed - speed).abs() < 0.01 ? AppPalette.auto(Color(0xFF4A7FD0)) : AppPalette.auto(Colors.black87);
                                                  return DropdownMenuItem<double>(value: speed, child: Center(child: Text("${speed}x", style: TextStyle(fontSize: 15, fontWeight: isWeight, color: isColor))));
                                                }).toList(),
                                                value: _currentSpeed,
                                                onChanged: (double? newSpeed) { if (newSpeed != null) { setState(() { _currentSpeed = newSpeed; }); for (final c in _controllers.values) { if (c.value.isInitialized) c.setPlaybackSpeed(_currentSpeed); } } },
                                                dropdownStyleData: DropdownStyleData(width: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppPalette.bg(Colors.white)), offset: const Offset(0, -8)),
                                                menuItemStyleData: const MenuItemStyleData(height: 38, padding: EdgeInsets.symmetric(horizontal: 14))
                                              )
                                            )
                                          ),
                                          const SizedBox(width: 10),
                                          _buildVideoAction(Icons.call_made, loc.translate('corner'), () {})
                                        ]
                                      ),
                                      const SizedBox(height: 14),
                                      // Title Text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(slideTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black))),
                                            const SizedBox(height: 4),
                                            Expanded(child: Text(slideTitleSub, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[800]!))))
                                          ]
                                        )
                                      )
                                    ]
                                  )
                                ));
                              }).toList(),
                            ),
                          ),
                          // const SizedBox(height: 6),
                          const SizedBox(height: 12),
                          // ===== 4) Next Button =====
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: _handleNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _current == _total - 1 ? AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.3) : AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                                  shadowColor: _current == _total - 1 ? AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9) : AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.8), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: Text(
                                  _current == _total - 1 ? AppLocalizations.of(context)!.translate('next_sub') : AppLocalizations.of(context)!.translate('Next'),
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppPalette.fg(Colors.white)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: () {Navigator.pop(context);},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.bg(Colors.grey).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                                  shadowColor: AppPalette.shadow(Colors.grey).withValues(alpha: 0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: Text(loc.translate('back'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.white)))
                              )
                            )
                          )
                        ]
                      )
                    )
                  )
              ]
            )
          )
        ),
      ),
    );
  }

  Widget _buildVideoAction(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.8), blurRadius: 12)]),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppPalette.fg(Colors.black54)),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
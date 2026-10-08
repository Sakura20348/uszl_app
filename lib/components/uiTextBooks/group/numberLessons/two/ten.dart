import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:signlang/components/uiTextBooks/group/numberLessons/numOnboardingProgress.dart';
import 'package:signlang/components/uiTextBooks/group/numberLessons/two/eleven.dart';
import 'package:video_player/video_player.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';
import '../../../../web/loading/bookLoading.dart';
import '../../../../web/saved/saved.dart';
import '../../../nameTextbooks/nameTextbooks.dart';

import 'package:signlang/services/theme_service.dart';
class Ten2 extends StatefulWidget{
  const Ten2({super.key});

  @override
  State<Ten2> createState() => _Ten2State();
}

class _Ten2State extends State<Ten2> {
  late VideoPlayerController _videoController;
  bool _isLoading = true;
  bool _isVideoInitialized = false;
  bool _isSaved = false;
  double _currentSpeed = 1.0;

  // ===== quiz state =====
  int? _selectedIndex;
  bool _isChecked = false;
  static const int _correctIndex = 0;

  List<String> _options(BuildContext context) => [
    AppLocalizations.of(context)!.translate('thirteen'), AppLocalizations.of(context)!.translate('fourteen'),
    AppLocalizations.of(context)!.translate('eleven'), AppLocalizations.of(context)!.translate('ten')
  ];

  @override
  void initState() { super.initState(); _initializePlayer(); _initData(); }

// =======================================================================
  void _handleNext() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Eleven2()));
    setState(() { _isChecked = false; _selectedIndex = null; });
  }

  Future<void> _handleSave() async {
    final options = _options(context);
    await SavedStore.instance.toggle({
      'word': options[0],
      'type': 'word',
      'source': 'textbook',
    });
    if (!mounted) return;
    setState(() { _isSaved = !_isSaved; });
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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(loc.translate('cancel'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.grey[700]!), fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () { Navigator.pop(dialogContext); Navigator.pushAndRemoveUntil(context, _slideLeftRoute(const MainWrapper(initialTab: 0)), (route) => false); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.bg(Color(0xFFEF9A9A)).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Color(0xFFB71C1C)).withValues(alpha: 0.9),
              side: BorderSide(width: 1, color: AppPalette.border(Color(0xFFB71C1C)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            ),
            child: Text(loc.translate('quit'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.red[900]!), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
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

// =======================================================================
  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.asset('assets/videos/numbers_fixed/13.mp4');
    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.play();
      setState(() => _isVideoInitialized = true);
    } catch (e) { debugPrint("Video init error: $e"); }
  }

  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initializeData() async { final results = await Future.wait([AppLoading.ready()]); if (!mounted) return; setState(() { _isLoading = false; }); }

  @override
  Widget build(BuildContext context){
    return PopScope(
      canPop: false, onPopInvokedWithResult: (didPop, result) { if (didPop) return; _showQuitDialog(); },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) { return notification.depth == 0; },
              child: CustomScrollView(
                slivers: [
                  if (_isLoading)
                    const SliverFillRemaining(hasScrollBody: false, child: Center(child: BookLoader(label: 'Loading')))
                  else
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ===== 1) back =====
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showQuitDialog(),
                                      child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.close))
                                    ),
                                    GestureDetector(
                                      onTap: _isChecked ? _handleSave : null,
                                      child: Container(
                                        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                                        child: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: _isChecked ? AppPalette.fg(Color(0xFF42A5F5)) : AppPalette.fg(Colors.grey.shade300))
                                      )
                                    )
                                  ]
                                ),
                                const SizedBox(height: 20),
                                // ===== 2) text and line =====
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text('10/20', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
                                      const SizedBox(height: 4), const NumOnboardingProgress(currentStep: 9)
                                    ]
                                  )
                                ),
                                const SizedBox(height: 16),
                                // ===== 3) video =====
                                Container(
                                  width: double.infinity, height: MediaQuery.of(context).size.height * 0.34, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(24)), clipBehavior: Clip.antiAlias,
                                  child: _isVideoInitialized ? AspectRatio(aspectRatio: _videoController.value.aspectRatio, child: VideoPlayer(_videoController)) : const Center(child: CircularProgressIndicator()),
                                ),
                                const SizedBox(height: 10),
                                // ===== 4) cards =====
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildVideoAction(Icons.refresh, AppLocalizations.of(context)!.translate('again'), () => _videoController.seekTo(Duration.zero)),
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
                                          onChanged: (double? newSpeed) { if (newSpeed != null) { setState(() { _currentSpeed = newSpeed; }); if (_isVideoInitialized) { _videoController.setPlaybackSpeed(_currentSpeed); } } },
                                          dropdownStyleData: DropdownStyleData(width: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppPalette.bg(Colors.white)), offset: const Offset(0, -8)),
                                          menuItemStyleData: const MenuItemStyleData(height: 38, padding: EdgeInsets.symmetric(horizontal: 14)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _buildVideoAction(Icons.call_made, AppLocalizations.of(context)!.translate('corner'), () {}),
                                  ],
                                ),
                                // ===== 5) text =====
                                const SizedBox(height: 20), Text(AppLocalizations.of(context)!.translate('what_num'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24)), const SizedBox(height: 16),
                                // answer options (2x2 grid)
                                Row(children: [Expanded(child: _buildOption(context, 0)), const SizedBox(width: 12), Expanded(child: _buildOption(context, 1))]), const SizedBox(height: 12),
                                Row(children: [Expanded(child: _buildOption(context, 2)), const SizedBox(width: 12), Expanded(child: _buildOption(context, 3))]), const Spacer(),
                                _buildBottomButton(context),
                              ],
                            ),
                            if (_isChecked) ...[Positioned(left: 0, right: 0, bottom: 80, child: _buildFeedbackBanner(context, _selectedIndex == _correctIndex))]
                          ],
                        ),
                      ),
                    )
                ],
              )
            )
          ),
        ),
      )
    );
  }

  // ======================== build ========================
  Widget _buildVideoAction(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.8), blurRadius: 12)]),
        child: Row(children: [Icon(icon, size: 16, color: AppPalette.fg(Colors.black54)), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))])
      )
    );
  }
  // ===== one answer option (pill with a radio circle) =====
  Widget _buildOption(BuildContext context, int index) {
    final String label = _options(context)[index];
    final bool isSelected = _selectedIndex == index;
    final bool isCorrect = index == _correctIndex;

    Color accent = AppPalette.auto(Colors.black26);
    if (_isChecked) { if (isCorrect) { accent = AppPalette.auto(Color(0xFF22C55E)); } else if (isSelected) { accent = AppPalette.auto(Color(0xFFEF4444)); } }
    else if (isSelected) { accent = AppPalette.auto(Color(0xFF4A7FD0)); }
    final bool highlighted = isSelected || (_isChecked && isCorrect);

    return GestureDetector(
      onTap: _isChecked ? null : () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18), border: Border.all(color: highlighted ? accent : AppPalette.border(Colors.white), width: 1.5),
          boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.25), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black87)))),
            const SizedBox(width: 6),
            Container(height: 22, width: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: highlighted ? accent : AppPalette.border(Colors.black26), width: highlighted ? 6 : 2)))
          ]
        )
      )
    );
  }

  // ===== green/red feedback banner shown after checking =====
  Widget _buildFeedbackBanner(BuildContext context, bool isCorrect) {
    final Color bg = isCorrect ? AppPalette.auto(Color(0xFFDCFCE7)) : AppPalette.auto(Color(0xFFFEE2E2));
    final Color fg = isCorrect ? AppPalette.auto(Color(0xFF16A34A)).withValues(alpha: 0.8) : AppPalette.auto(Color(0xFFDC2626)).withValues(alpha: 0.8);
    final Color sc = isCorrect ? AppPalette.auto(Color(0xFF16A34A)).withValues(alpha: 0.9) : AppPalette.auto(Color(0xFFDC2626)).withValues(alpha: 0.9);
    final String correctLabel = _options(context)[_correctIndex];

    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: sc, blurRadius: 15)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: isCorrect
              ? Text(AppLocalizations.of(context)!.translate('answer_correct'), style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600))
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.translate('answer_wrong'), style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${AppLocalizations.of(context)!.translate('correct_answer')}: $correctLabel', style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w400)),
                ],
              )
          ),
          Icon(Icons.flag_outlined, color: fg, size: 18),
        ],
      ),
    );
  }

  // ===== bottom button: "check answer" -> "next question" =====
  Widget _buildBottomButton(BuildContext context) {
    final bool isCorrect = _selectedIndex == _correctIndex;
    final bool canCheck = _selectedIndex != null;

    // colours per state
    Color bg; Color fg; Color sc;
    if (!_isChecked) {
      bg = AppPalette.auto(Color(0xFF4A7FD0)).withValues(alpha: 0.15);
      fg = canCheck ? AppPalette.auto(Colors.blue[900]!) : AppPalette.auto(Colors.blue[700]!);
      sc = AppPalette.auto(Color(0xFFBBDEFB)).withValues(alpha: 0.9);
    } else if (isCorrect) {
      bg = AppPalette.auto(Color(0xFF4CAF50)).withValues(alpha: 0.2);
      fg = AppPalette.auto(Colors.white);
      sc = AppPalette.auto(Color(0xFF1B5E20)).withValues(alpha: 0.9);
    } else {
      bg = AppPalette.auto(Color(0xFFF44336)).withValues(alpha: 0.2);
      fg = AppPalette.auto(Colors.white);
      sc = AppPalette.auto(Color(0xFFB71C1C)).withValues(alpha: 0.9);
    }
    final String label = _isChecked ? AppLocalizations.of(context)!.translate('next_question') : AppLocalizations.of(context)!.translate('check_answer_btn');
    void handleCheck() { setState(() { _isChecked = true; if (_selectedIndex == _correctIndex) { LessonProgress.instance.addCorrect(); } else { LessonProgress.instance.addWrong(); } }); }

    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _isChecked ? _handleNext : (canCheck ? handleCheck : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, disabledBackgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: fg, elevation: 6, shadowColor: sc,
          side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg)), const SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18, color: fg)]
        )
      )
    );
  }
}
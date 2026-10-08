import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:signlang/components/uiTextBooks/group/numberLessons/two/exam/examOne.dart';
import 'package:video_player/video_player.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';
import '../../../../web/loading/bookLoading.dart';
import '../../../../web/saved/saved.dart';
import '../../../nameTextbooks/nameTextbooks.dart';
import '../numOnboardingProgress.dart';

import 'package:signlang/services/theme_service.dart';
class Twenty2 extends StatefulWidget{
  const Twenty2({super.key});

  @override
  State<Twenty2> createState() => _Twenty2State();
}

class _Twenty2State extends State<Twenty2> {
  late VideoPlayerController _videoController;
  bool _isSaved = false;
  bool _isLoading = true;
  bool _isVideoInitialized = false;
  double _currentSpeed = 1.0;
  bool _isChecked = false;

  late final List<String> _bankWords = [
    AppLocalizations.of(context)!.translate('fifteen'), AppLocalizations.of(context)!.translate('eighteen'),
    AppLocalizations.of(context)!.translate('nineteen'), AppLocalizations.of(context)!.translate('eleven'),
  ];

  late final List<String> _correctOrder = [ AppLocalizations.of(context)!.translate('fifteen') ];

  final List<int> _answer = [];
  bool _checked = false;

  bool get _isSolved {
    final built = _answer.map((i) => _bankWords[i].toLowerCase()).toList();
    final target = _correctOrder.map((w) => w.toLowerCase()).toList();
    if (built.length != target.length) return false;
    for (int i = 0; i < built.length; i++) { if (built[i] != target[i]) return false; }
    return true;
  }

  @override
  void initState() { super.initState(); _initializePlayer(); _initData(); }
  void _placeWord(int bankIndex) { if (_answer.contains(bankIndex)) return; setState(() { _answer.add(bankIndex); _checked = false; }); }
  void _removeWord(int bankIndex) { setState(() { _answer.remove(bankIndex); _checked = false; }); }

// =======================================================================
  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.asset('assets/videos/numbers_fixed/15.mp4');
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

  // =======================================================================
  void _handleNext() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamOne2()));
    setState(() { _isChecked = false; _answer.clear(); });
  }

  Future<void> _handleSave() async {
    await SavedStore.instance.toggle({
      'word': _bankWords[0],
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, onPopInvokedWithResult: (didPop, result) { if (didPop) return; _showQuitDialog(); },
      child: Scaffold(
        body: Container(
          width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
              child: CustomScrollView(
                slivers: [
                  if(_isLoading)
                  // ======= 1 =======
                    const SliverFillRemaining(hasScrollBody: false, child: Center(child: BookLoader(label: 'Loading')))
                  else
                  // ======= 2 =======
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
                                      Text('20/20', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
                                      const SizedBox(height: 4), const NumOnboardingProgress(currentStep: 19)
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
                                                Text("${_currentSpeed}x", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black))),
                                              ],
                                            ),
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
                                const SizedBox(height: 16),
                                // ===== 4) text =====
                                Align(alignment: Alignment.centerLeft, child: Text(AppLocalizations.of(context)!.translate('what_num'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A))))),
                                const SizedBox(height: 14),
                                // ===== 5) cards move to box =====
                                // --- answer row top ---
                                Container(
                                  width: double.infinity, constraints: const BoxConstraints(minHeight: 70), padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                                  child: Wrap(
                                    spacing: 10, runSpacing: 10,
                                    children: _answer.map((bankIndex) { return _buildChip(_bankWords[bankIndex], onTap: () => _removeWord(bankIndex), borderColor: _checked ? AppPalette.border(Colors.redAccent) : AppPalette.border(Color(0xFF22C55E))); }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // --- word bank bottom ---
                                Wrap(
                                  spacing: 10, runSpacing: 10,
                                  children: List.generate(_bankWords.length, (i) {
                                    final used = _answer.contains(i);
                                    if (used) return _buildEmptySlot(_bankWords[i]);
                                    return _buildChip(_bankWords[i], onTap: () => _placeWord(i), borderColor: Colors.transparent);
                                  }),
                                ),
                                const SizedBox(height: 16),
                                _buildBottomButton(context),
                              ],
                            ),
                            if (_isChecked) ...[Positioned(left: 0, right: 0, bottom: 80, child: _buildFeedbackBanner(context, _isSolved))],
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

  Widget _buildChip(String text, {required VoidCallback onTap, required Color borderColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: 2),
          boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF334155)))),
      ),
    );
  }

  Widget _buildEmptySlot(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppPalette.border(Colors.grey).withValues(alpha: 0.4), width: 1.5)),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.transparent)),
    );
  }
  // ===== green/red feedback banner shown after checking =====
  Widget _buildFeedbackBanner(BuildContext context, bool isCorrect) {
    final Color bg = isCorrect ? AppPalette.auto(Color(0xFFDCFCE7)) : AppPalette.auto(Color(0xFFFEE2E2));
    final Color fg = isCorrect ? AppPalette.auto(Color(0xFF16A34A)).withValues(alpha: 0.8) : AppPalette.auto(Color(0xFFDC2626)).withValues(alpha: 0.8);
    final Color sc = isCorrect ? AppPalette.auto(Color(0xFF16A34A)).withValues(alpha: 0.9) : AppPalette.auto(Color(0xFFDC2626)).withValues(alpha: 0.9);
    final String correctLabel = _correctOrder.join(' ');

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
                  Text('${AppLocalizations.of(context)!.translate('correct_answer')}: $correctLabel', style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w400))
                ]
              )
          ),
          Icon(Icons.flag_outlined, color: fg, size: 18),
        ],
      ),
    );
  }
  // ===== bottom button: "check answer" -> "next question" =====
  Widget _buildBottomButton(BuildContext context) {
    final bool isCorrect = _isSolved;
    final bool canCheck = _answer.isNotEmpty;

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
    void handleCheck() { setState(() { _isChecked = true; if (_isSolved) { LessonProgress.instance.addCorrect(); } else { LessonProgress.instance.addWrong(); } }); }

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
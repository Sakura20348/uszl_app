import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:signlang/components/lessonProgress/wellDone.dart';
import 'package:signlang/components/log/onboardingProgress.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import 'package:signlang/services/theme_service.dart';
class Order extends StatefulWidget{
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order>{
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  double _currentSpeed = 1.0;

  late final List<String> _bankWords = [
    AppLocalizations.of(context)!.translate('hello'),
    AppLocalizations.of(context)!.translate('nice_to'),
    AppLocalizations.of(context)!.translate('meet'),
    AppLocalizations.of(context)!.translate('you')
  ];

  late final List<String> _correctOrder = [
    AppLocalizations.of(context)!.translate('nice_to'),
    AppLocalizations.of(context)!.translate('meet'),
    AppLocalizations.of(context)!.translate('you')
  ];

  final List<int> _answer = [];
  bool _checked = false;

  void _placeWord(int bankIndex) { if (_answer.contains(bankIndex)) return; setState(() { _answer.add(bankIndex); _checked = false; }); }

  void _removeWord(int bankIndex) { setState(() { _answer.remove(bankIndex); _checked = false; }); }

  bool get _isSolved {
    final built = _answer.map((i) => _bankWords[i].toLowerCase()).toList();
    final target = _correctOrder.map((w) => w.toLowerCase()).toList();
    if (built.length != target.length) return false;
    for (int i = 0; i < built.length; i++) { if (built[i] != target[i]) return false; }
    return true;
  }

  void _handleNext() {
    if (!_isSolved) {
      setState(() => _checked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('wrong_answer')), backgroundColor: AppPalette.bg(Colors.redAccent), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WellDone()));
  }

  @override
  void initState() { super.initState(); _initializePlayer(); }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.asset('assets/videos/numbers_fixed/2.mp4');
    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.play();
      setState(() => _isVideoInitialized = true);
    } catch (e) { debugPrint("Video init error: $e"); }
  }

  @override
  void dispose() { if (_isVideoInitialized) _videoController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // ===== 1) back =====
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.arrow_back_outlined),)
                      ),
                      const SizedBox(width: 20),
                      const OnboardingProgress(currentStep: 7),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ===== 2) video =====
                  Container(
                    width: double.infinity, height: MediaQuery.of(context).size.height * 0.34, decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(24)), clipBehavior: Clip.antiAlias,
                    child: _isVideoInitialized ? AspectRatio(aspectRatio: _videoController.value.aspectRatio, child: VideoPlayer(_videoController)) : const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 10),

                  // ===== 3) cards =====
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
                              final Color isColor = (_currentSpeed - speed).abs() < 0.01 ? AppPalette.fg(Color(0xFF4A7FD0)) : AppPalette.fg(Colors.black87);
                              return DropdownMenuItem<double>(value: speed, child: Center(child: Text("${speed}x", style: TextStyle(fontSize: 15, fontWeight: isWeight, color: isColor))));
                            }).toList(),
                            value: _currentSpeed, onChanged: (double? newSpeed) { if (newSpeed != null) { setState(() { _currentSpeed = newSpeed; }); if (_isVideoInitialized) { _videoController.setPlaybackSpeed(_currentSpeed); } } },
                            dropdownStyleData: DropdownStyleData(width: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppPalette.bg(Colors.white)), offset: const Offset(0, -8)),
                            menuItemStyleData: const MenuItemStyleData(height: 38, padding: EdgeInsets.symmetric(horizontal: 14))
                          )
                        )
                      ),
                      const SizedBox(width: 10),
                      _buildVideoAction(Icons.call_made, AppLocalizations.of(context)!.translate('corner'), () {}),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ===== 4) text =====
                  Align(alignment: Alignment.centerLeft, child: Text(AppLocalizations.of(context)!.translate('order'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A))))),
                  const SizedBox(height: 14),
                  // ===== 5) cards move to box =====
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- answer row top ---
                        Container(
                          width: double.infinity, constraints: const BoxConstraints(minHeight: 70), padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                          child: Wrap(
                            spacing: 10, runSpacing: 10,
                            children: _answer.map((bankIndex) { return _buildChip(_bankWords[bankIndex], onTap: () => _removeWord(bankIndex), borderColor: _checked ? AppPalette.border(Colors.redAccent) : AppPalette.border(Color(0xFF22C55E))); }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // --- word bank bottom ---
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: List.generate(_bankWords.length, (i) {
                            final used = _answer.contains(i);
                            if (used) return _buildEmptySlot(_bankWords[i]);
                            return _buildChip(_bankWords[i], onTap: () => _placeWord(i), borderColor: Colors.transparent);
                          }),
                        ),
                      ],
                    ),
                  ),

                  // ===== 6) button =====
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSolved ? AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1) : AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), foregroundColor: AppPalette.fg(Colors.white),
                        elevation: _isSolved ? 6 : 0, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                        side: BorderSide(width: 1, color: _isSolved ? AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2) : AppPalette.border(Colors.black12))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('check_answer'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isSolved ? AppPalette.fg(Colors.blue[900]!) : AppPalette.fg(Colors.blue[700]!),),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward_outlined, color: _isSolved ? AppPalette.fg(Colors.blue[900]!) : AppPalette.fg(Colors.blue[700]!), size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ),
        ),
      ),
    );
  }

  // ======================== build ========================
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

  Widget _buildVideoAction(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.8), blurRadius: 12)]),
        child: Row(children: [Icon(icon, size: 16, color: AppPalette.fg(Colors.black54)), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))])
      )
    );
  }
}
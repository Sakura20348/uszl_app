import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:signlang/components/lessonProgress/matching.dart';
import 'package:signlang/components/log/nameLog/nameLogItem.dart';
import 'package:signlang/components/log/onboardingProgress.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import 'package:signlang/services/theme_service.dart';
class SelectOneIllustration extends StatefulWidget{
  const SelectOneIllustration({super.key});

  @override
  State<SelectOneIllustration> createState() => _SelectOneIllustrationState();
}

class _SelectOneIllustrationState extends State<SelectOneIllustration> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  int _selectedIndex = -1;
  bool _hasError = false;
  bool _isCorrect = false;
  double _currentSpeed = 1.0;

  final int _correctAnswerIndex = 3;

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

  void _handleValidation() {
    if (_selectedIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('wrong_answer')), backgroundColor: AppPalette.bg(Colors.black), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_selectedIndex == _correctAnswerIndex) {
      setState(() { _hasError = false; _isCorrect = true; });
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Matching()) );
    } else {
      setState(() { _hasError = true; _isCorrect = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('wrong_answer_sub')), backgroundColor: AppPalette.bg(Colors.redAccent), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() { _videoController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final quizOptionsData = QuizOptionsData(context: context);
    final quizOptionsItems = quizOptionsData.storeQuizOptions['0'] ?? [];

    return Scaffold(
      backgroundColor: AppPalette.bg(Color(0xFFF4F7FC)),
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
                        child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.arrow_back_outlined))
                      ),
                      const SizedBox(width: 20),
                      const OnboardingProgress(currentStep: 5),
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
                                  Text("${_currentSpeed}x", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black))),
                                ],
                              ),
                            ),
                            items: [0.5, 1.0, 1.5].map<DropdownMenuItem<double>>((double speed) {
                              final isWeight = (_currentSpeed - speed).abs() < 0.01 ? FontWeight.bold : FontWeight.normal;
                              final Color isColor = (_currentSpeed - speed).abs() < 0.01 ? AppPalette.fg(Color(0xFF4A7FD0)) : AppPalette.fg(Colors.black87);
                              return DropdownMenuItem<double>(value: speed, child: Center(child: Text("${speed}x", style: TextStyle(fontSize: 15, fontWeight: isWeight, color: isColor))));
                            }).toList(),
                            value: _currentSpeed, onChanged: (double? newSpeed) { if (newSpeed != null) { setState(() { _currentSpeed = newSpeed; }); if (_isVideoInitialized) { _videoController.setPlaybackSpeed(_currentSpeed); } } },
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
                  Align(alignment: Alignment.centerLeft, child: Text(AppLocalizations.of(context)!.translate('video_mark'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A))))),
                  const SizedBox(height: 10),
                  // ===== 5) click to cards sign lang =====
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.29),
                      itemCount: quizOptionsItems.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedIndex == index;
                        final showAsWrong = isSelected && _hasError;
                        final showAsCorrect = isSelected && _isCorrect;
                        // === color ===
                        final asCorrect = showAsCorrect ? AppPalette.auto(Color(0xFF22C55E)) : showAsWrong ? AppPalette.auto(Colors.redAccent) : (isSelected ? AppPalette.auto(Color(0xFF4A7FD0)) : Colors.transparent);
                        final shadowAsCorrect = showAsCorrect ? AppPalette.auto(Color(0xFF22C55E)) : showAsWrong ? AppPalette.auto(Colors.redAccent) : AppPalette.auto(Color(0xFF42A5F5));
                        final radioAsCorrect = showAsCorrect ? AppPalette.auto(Color(0xFF22C55E)) : showAsWrong ? AppPalette.auto(Colors.red) : (isSelected ? AppPalette.auto(Color(0xFF4A7FD0)) : AppPalette.auto(Colors.black12));
                        Icon errorAsBuilder(_, __, ___) => Icon(Icons.person, size: 60, color: AppPalette.fg(Colors.blue));

                        return GestureDetector(
                          onTap: () { setState(() { _selectedIndex = index; _hasError = false; _isCorrect = false; }); },
                          child: Container(
                            padding: EdgeInsets.fromLTRB(12, 12, 12, isSelected ? 0 : 12),
                            decoration: BoxDecoration(
                              color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(20), border: Border.all(color: asCorrect, width: 2),
                              boxShadow: isSelected ? [BoxShadow(color: (shadowAsCorrect).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))] : null,
                            ),
                            child: Stack(
                              children: [
                                // --- 1) image ---
                                Positioned.fill(
                                  bottom: isSelected ? 0 : 10,
                                  child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset(quizOptionsItems[index]['image'], fit: BoxFit.contain, errorBuilder: errorAsBuilder)),
                                ),
                                // --- 2) label ---
                                Positioned(
                                  bottom: 12, left: 10, right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16), border: Border.all(width: isSelected ? 0.5 : 0.1)),
                                    child: Text(
                                      quizOptionsItems[index]['label'], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isSelected ? AppPalette.fg(Color(0xFF1E293B)) : AppPalette.fg(Colors.grey)),
                                    )
                                  )
                                ),
                                // --- 3) radio ---
                                Positioned(top: 5, right: 5, child: Container(height: 22, width: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: radioAsCorrect, width: isSelected ? 6 : 2))))
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ===== 6) button =====
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleValidation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedIndex == -1 ? AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1) : AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), foregroundColor: AppPalette.fg(Colors.white),
                        elevation: _selectedIndex == -1 ? 0 : 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                        side: BorderSide(width: 1, color: _selectedIndex == -1 ? AppPalette.border(Colors.black12) : AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('check_answer'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _selectedIndex == -1 ? AppPalette.fg(Colors.blue[700]!) : AppPalette.fg(Colors.blue[900]!),)
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_outlined, color: _selectedIndex == -1 ? AppPalette.fg(Colors.blue[700]!) : AppPalette.fg(Colors.blue[900]!), size: 16)
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
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.8), blurRadius: 12)]),
        child: Row(children: [Icon(icon, size: 16, color: AppPalette.fg(Colors.black54)), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))])
      )
    );
  }
}
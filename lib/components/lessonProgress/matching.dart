import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:signlang/components/lessonProgress/order.dart';
import 'package:signlang/components/log/onboardingProgress.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

import 'package:signlang/services/theme_service.dart';
class Matching extends StatefulWidget{
  const Matching({super.key});

  @override
  State<Matching> createState() => _MatchingState();
}

class _MatchingState extends State<Matching>{
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  double _currentSpeed = 1.0;
  int? _selectedLeftIndex;
  final Set<String> _matchedRightIds = {};
  int? _errorRightIndex;

  final List<Map<String, dynamic>> _leftItems = const [
    {'id': '0', 'matchId': '1'}, {'id': '1', 'matchId': null},
    {'id': '2', 'matchId': null}, {'id': '3', 'matchId': null},
  ];

  late final List<Map<String, dynamic>> _rightItems = [
    {'id': '0', 'label': '${AppLocalizations.of(context)!.translate('five')} (5)'},
    {'id': '1', 'label': '${AppLocalizations.of(context)!.translate('two')} (2)'},
    {'id': '2', 'label': '${AppLocalizations.of(context)!.translate('six')} (6)'},
    {'id': '3', 'label': "${AppLocalizations.of(context)!.translate('nine')} (9)"},
  ];

  void _handleLeftTap(int index) {
    final matchId = _leftItems[index]['matchId'];
    if (matchId != null && _matchedRightIds.contains(matchId)) return;
    setState(() { _selectedLeftIndex = index; _errorRightIndex = null; });
  }

  void _handleRightTap(int index) {
    if (_selectedLeftIndex == null) return;
    final rightId = _rightItems[index]['id'];
    if (_matchedRightIds.contains(rightId)) return;
    final correctId = _leftItems[_selectedLeftIndex!]['matchId'];

    setState(() {
      if (correctId != null && correctId == rightId) {
        _matchedRightIds.add(rightId);
        _selectedLeftIndex = null;
        _errorRightIndex = null;
      } else { _errorRightIndex = index; }
    });
  }

  bool get _isSolved => _matchedRightIds.contains('1');

  void _handleNext() {
    if (!_isSolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('wrong_answer')), backgroundColor: AppPalette.bg(Colors.black), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => const Order()));
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
  void dispose() {
    if (_isVideoInitialized) _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
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
                        child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.arrow_back_outlined))
                      ),
                      const SizedBox(width: 20),
                      const OnboardingProgress(currentStep: 6),
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
                      _buildVideoAction(Icons.refresh, loc.translate('again'), () => _videoController.seekTo(Duration.zero)),
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
                      _buildVideoAction(Icons.call_made, loc.translate('corner'), () {})
                    ]
                  ),
                  const SizedBox(height: 16),
                  // ===== 4) text =====
                  Align(alignment: Alignment.centerLeft, child: Text(loc.translate('what_number'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A))))),
                  const SizedBox(height: 12),
                  // ===== 5) voice and cards =====
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- left voice ---
                        Expanded(
                          child: Column(
                            children: List.generate(_leftItems.length, (index) {
                              final matchId = _leftItems[index]['matchId'];
                              final isSelected = _selectedLeftIndex == index;
                              final isMatched = matchId != null && _matchedRightIds.contains(matchId);
                              return Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: _buildLeftCard(index, isSelected, isMatched)));
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // --- right answer labels ---
                        Expanded(
                          child: Column(
                            children: List.generate(_rightItems.length, (index) {
                              final rightId = _rightItems[index]['id'];
                              final isMatched = _matchedRightIds.contains(rightId);
                              final isError = _errorRightIndex == index;
                              return Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: _buildRightCard(index, isMatched, isError)));
                            }),
                          ),
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
                          Text(loc.translate('check_answer'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isSolved ? AppPalette.fg(Colors.blue[900]!) : AppPalette.fg(Colors.blue[700]!))),
                          SizedBox(width: 10),
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
  Widget _buildVideoAction(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.8), blurRadius: 12)]),
        child: Row(children: [Icon(icon, size: 16, color: AppPalette.fg(Colors.black54)), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))])
      ),
    );
  }

  Widget _buildLeftCard(int index, bool isSelected, bool isMatched) {
    final Color borderColor = isMatched ? AppPalette.auto(Color(0xFF22C55E)) : (isSelected ? AppPalette.auto(Color(0xFF4A7FD0)) : Colors.transparent);

    return GestureDetector(
      onTap: () => _handleLeftTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor, width: 2),
          boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(child: Icon(Icons.play_arrow, size: 26, color: isMatched ? AppPalette.fg(Color(0xFF22C55E)) : AppPalette.fg(Color(0xFF4A7FD0)))),
      ),
    );
  }

  Widget _buildRightCard(int index, bool isMatched, bool isError) {
    final Color borderColor = isMatched ? AppPalette.auto(Color(0xFF22C55E)) : (isError ? AppPalette.auto(Colors.redAccent) : Colors.transparent);
    final Color textColor = isMatched ? AppPalette.auto(Color(0xFF15803D)) : (isError ? AppPalette.auto(Colors.redAccent) : AppPalette.auto(Color(0xFF334155)));

    return GestureDetector(
      onTap: () => _handleRightTap(index),
      child: Container(
        alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor, width: 2),
          boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(_rightItems[index]['label'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
      ),
    );
  }
}

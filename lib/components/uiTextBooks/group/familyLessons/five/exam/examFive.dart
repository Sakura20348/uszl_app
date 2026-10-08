import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:flutter/services.dart';
import 'package:signlang/components/uiTextBooks/group/familyLessons/famOnboardingProgress.dart';
import 'package:signlang/components/uiTextBooks/group/familyLessons/five/exam/examSix.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../main.dart';
import '../../../../../web/loading/bookLoading.dart';
import '../../../../nameTextbooks/nameTextbooks.dart';

import 'package:signlang/services/theme_service.dart';
class ExamWords5Five extends StatefulWidget{
  const ExamWords5Five({super.key});

  @override
  State<ExamWords5Five> createState() => _ExamWords5FiveState();
}

class _ExamWords5FiveState extends State<ExamWords5Five> {
  bool _isLoading = true;
  bool _isChecked = false;
  int? _selectedLeftIndex;
  final Set<String> _matchedRightIds = {};
  int? _errorRightIndex;

  bool get _allMatched => _matchedRightIds.length == _rightItems.length;

  final List<Map<String, dynamic>> _leftItems = const [
    {'id': '0', 'matchId': '3'}, {'id': '1', 'matchId': '2'},
    {'id': '2', 'matchId': '0'}, {'id': '3', 'matchId': '1'},
  ];

  late final List<Map<String, dynamic>> _rightItems = [
    {'id': '0', 'images': ''},// divorce
    {'id': '1', 'images': ''},// husband
    {'id': '2', 'images': ''},// wife
    {'id': '3', 'images': ''},// lover
  ];

  @override
  void initState() { super.initState(); _initData(); }

  void _handleLeftTap(int index) {
    if (_matchedRightIds.contains(_leftItems[index]['matchId'])) return;
    setState(() => _selectedLeftIndex = index);
  }

  void _handleRightTap(int index) {
    if (_selectedLeftIndex == null) return;
    final leftMatchId = _leftItems[_selectedLeftIndex!]['matchId'];
    final rightId = _rightItems[index]['id'];
    setState(() {
      if (leftMatchId == rightId) {
        _matchedRightIds.add(rightId);
        _selectedLeftIndex = null;
        _errorRightIndex = null;
      } else { _errorRightIndex = index; }
    });
  }

// =======================================================================
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initializeData() async { final results = await Future.wait([AppLoading.ready()]); if (!mounted) return; setState(() { _isLoading = false; }); }

  // =======================================================================
  void _handleNext() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamWords5Six()));

    setState(() {
      _isChecked = false;
      _matchedRightIds.clear();
      _selectedLeftIndex = null;
      _errorRightIndex = null;
    });
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
            onPressed: () { Navigator.pop(dialogContext); Navigator.pushAndRemoveUntil(context, _slideLeftRoute(const MainWrapper(initialTab: 0)), (route) => false); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.bg(Color(0xFFEF9A9A)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
              shadowColor: AppPalette.shadow(Color(0xFFB71C1C)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFFB71C1C)).withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
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

  void _onSkipQuestion() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppPalette.border(Colors.white), width: 1)),
        elevation: 15, backgroundColor: AppPalette.bg(Colors.white).withOpacity(0.7), shadowColor: AppPalette.shadow(Color(0xFF42A5F5)).withOpacity(0.9),
        title: Text('${AppLocalizations.of(context)!.translate('skip_question')}?', style: TextStyle(fontWeight: FontWeight.w700, color: AppPalette.fg(Color(0xFF0F172A)))),
        content: Text(AppLocalizations.of(context)!.translate('skip_question_sub'), style: TextStyle(color: AppPalette.fg(Colors.grey[800]!), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.translate('keep'), style: TextStyle(color: AppPalette.fg(Colors.black), fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx);Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamWords5Six())); },
            child: Text(AppLocalizations.of(context)!.translate('skip_question'), style: TextStyle(color: AppPalette.fg(Color(0xFF006064)).withOpacity(0.8), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context){
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false, onPopInvokedWithResult: (didPop, result) { if (didPop) return; _showQuitDialog(); },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
              child: CustomScrollView(
                slivers: [
                  if(_isLoading)
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
                                GestureDetector(
                                  onTap: () => _showQuitDialog(),
                                  child: Container(
                                    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                                    child: const Icon(Icons.close),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // ===== 2) text and line =====
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text('4/6', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
                                      const SizedBox(height: 4), const ExamFamOnboardingProgress(currentStep: 3)
                                    ]
                                  )
                                ),
                                const SizedBox(height: 16),
                                // ===== 3) text =====
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(loc.translate('what_words'), style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A)))),
                                ),
                                const SizedBox(height: 12),
                                // ===== 4) voice and cards =====
                                SizedBox(
                                  height: 380,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // --- left voice ---
                                      SizedBox(
                                        width: 170,
                                        child: Column(
                                          children: List.generate(_leftItems.length, (index) {
                                            final matchId = _leftItems[index]['matchId'];
                                            final isSelected = _selectedLeftIndex == index;
                                            final isMatched = matchId != null && _matchedRightIds.contains(matchId);
                                            return Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: _buildLeftCard(index, isSelected, isMatched)));
                                          }),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // --- right answer labels ---
                                      SizedBox(
                                        width: 170,
                                        child: Column(
                                          children: List.generate(_rightItems.length, (index) {
                                            final rightId = _rightItems[index]['id'];
                                            final isMatched = _matchedRightIds.contains(rightId);
                                            final isError = _errorRightIndex == index;
                                            return Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: _buildRightCard(index, isMatched, isError)));
                                          }),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // ===== 5) button =====
                                _buildBottomButton(context),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _onSkipQuestion,
                                  child: Container(
                                    width: double.infinity, height: 56,
                                    decoration: BoxDecoration(
                                      color: AppPalette.bg(Colors.white).withOpacity(0.4), borderRadius: BorderRadius.circular(150), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
                                      boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withOpacity(0.9), blurRadius: 15)],
                                    ),
                                    child: Center(
                                      child: Text(loc.translate('skip_for_now'), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF334155)))),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            if (_isChecked) ...[Positioned(left: 0, right: 0, bottom: 140, child: _buildFeedbackBanner(context, _allMatched))],
                          ],
                        ),
                      ),
                    )
                ],
              ),
            )
          ),
        ),
      )
    );
  }
  // ===== green/red feedback banner shown after checking =====
  Widget _buildFeedbackBanner(BuildContext context, bool _allMatched) {
    final Color bg = _allMatched ? AppPalette.auto(Color(0xFFDCFCE7)) : AppPalette.auto(Color(0xFFFEE2E2));
    final Color fg = _allMatched ? AppPalette.auto(Color(0xFF16A34A)).withOpacity(0.8) : AppPalette.auto(Color(0xFFDC2626)).withOpacity(0.8);
    final Color sc = _allMatched ? AppPalette.auto(Color(0xFF16A34A)).withOpacity(0.9) : AppPalette.auto(Color(0xFFDC2626)).withOpacity(0.9);

    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: sc, blurRadius: 15)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_allMatched ? Icons.check_circle : Icons.cancel, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.translate(_allMatched ? 'answer_correct' : 'answer_wrong'),
              style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.flag_outlined, color: fg, size: 18),
        ],
      ),
    );
  }
  // ===== bottom button: "check answer" -> "next question" =====
  Widget _buildBottomButton(BuildContext context) {
    final bool isCorrect = _allMatched;
    final bool canCheck = _matchedRightIds.isNotEmpty;
    final AppLocalizations loc = AppLocalizations.of(context)!;

    // colours per state
    Color bg; Color fg; Color sc;
    if (!_isChecked) {
      bg = AppPalette.auto(Color(0xFF4A7FD0)).withOpacity(0.15);
      fg = canCheck ? AppPalette.auto(Colors.blue[900]!) : AppPalette.auto(Colors.blue[700]!);
      sc = AppPalette.auto(Color(0xFFBBDEFB)).withOpacity(0.9);
    } else if (isCorrect) {
      bg = AppPalette.auto(Color(0xFF4CAF50)).withOpacity(0.2);
      fg = AppPalette.auto(Colors.white);
      sc = AppPalette.auto(Color(0xFF1B5E20)).withOpacity(0.9);
    } else {
      bg = AppPalette.auto(Color(0xFFF44336)).withOpacity(0.2);
      fg = AppPalette.auto(Colors.white);
      sc = AppPalette.auto(Color(0xFFB71C1C)).withOpacity(0.9);
    }

    final String label = _isChecked ? loc.translate('next_question') : loc.translate('check_answer_btn');
    void handleCheck() { setState(() { _isChecked = true; if (_allMatched) { LessonProgress.instance.addCorrect(); } else { LessonProgress.instance.addWrong(); } }); }

    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _isChecked ? _handleNext : (canCheck ? handleCheck : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, disabledBackgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withOpacity(0.1), foregroundColor: fg, elevation: 6, shadowColor: sc,
          side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18, color: fg),
          ],
        ),
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
          boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Center(
          child: (_rightItems[index]['images'] is String && (_rightItems[index]['images'] as String).isNotEmpty) ? Image.asset( _rightItems[index]['images'],
            width: isMatched ? 86 : 76, height: isMatched ? 96 : 86, errorBuilder: (_, __, ___) => Icon(Icons.person, size: 60, color: AppPalette.fg(Colors.blue)),
          ) : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
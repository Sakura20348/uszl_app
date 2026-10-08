import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:signlang/components/uiTextBooks/group/foodLessons/three/exam/examThree.dart';
import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks2.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../main.dart';
import '../../../../../web/loading/bookLoading.dart';
import '../../../../nameTextbooks/nameTextbooks.dart';
import '../../foodOnboardingProgress.dart';

import 'package:signlang/services/theme_service.dart';
class ExamFood3Two extends StatefulWidget {
  const ExamFood3Two({super.key});

  @override
  State<ExamFood3Two> createState() => _ExamFood3TwoState();
}

class _ExamFood3TwoState extends State<ExamFood3Two> {
  bool _isLoading = true;
  bool _isChecked = false;
  int? _selectedIndex;
  static const int _correctIndex = 1;

  late final examFoodData = ExamFood3Data(context: context);
  late final examFoodItem = examFoodData.storeExamWords['0'] ?? [];

  @override
  void initState() { super.initState(); _initData(); }

// =======================================================================
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initializeData() async { final results = await Future.wait([AppLoading.ready()]); if (!mounted) return; setState(() { _isLoading = false; }); }

  // =======================================================================
  void _handleNext() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamFood3Three()));
    setState(() { _isChecked = false; _selectedIndex = null; });
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
              backgroundColor: AppPalette.bg(Color(0xFFEF9A9A)).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
              shadowColor: AppPalette.shadow(Color(0xFFB71C1C)).withValues(alpha: 0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFFB71C1C)).withValues(alpha: 0.2)),
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

  @override
  Widget build(BuildContext context){
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
                                      Text('1/7', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
                                      const SizedBox(height: 4), const ExamFoodOnboardingProgress(currentStep: 0)
                                    ]
                                  )
                                ),
                                const SizedBox(height: 16),
                                // ===== 3) text =====
                                Text(AppLocalizations.of(context)!.translate('where_meat'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 28)),
                                const SizedBox(height: 20),
                                // ===== 4) click to cards =====
                                SizedBox(
                                  height: 390,
                                  child: GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15),
                                    itemCount: examFoodItem.length,
                                    itemBuilder: (context, index) {
                                      final isSelected = _selectedIndex == index;
                                      final bool isCorrect = index == _correctIndex;
                                      Color accent = AppPalette.auto(Colors.black26);
                                      if (_isChecked) { if (isCorrect) { accent = AppPalette.auto(Color(0xFF22C55E)); } else if (isSelected) { accent = AppPalette.auto(Color(0xFFEF4444)); } } else if (isSelected) { accent = AppPalette.auto(Color(0xFF4A7FD0)); }
                                      final bool highlighted = isSelected || (_isChecked && isCorrect);
                                      final Color isColor = highlighted ? accent : (isSelected ? AppPalette.auto(Color(0xFF4A7FD0)) : AppPalette.auto(Colors.black12));
                                      return GestureDetector(
                                        onTap: _isChecked ? null : () => setState(() => _selectedIndex = index),
                                        child: Container(
                                          padding: EdgeInsets.fromLTRB(12, 12, 12, isSelected ? 0 : 12),
                                          decoration: BoxDecoration(
                                            color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(20), border: Border.all(color: highlighted ? accent : (isSelected ? AppPalette.auto(Color(0xFF4A7FD0)) : Colors.transparent), width: 2),
                                            boxShadow: isSelected ? [BoxShadow(color: (highlighted ? AppPalette.auto(Colors.red) : AppPalette.auto(Color(0xFF42A5F5))).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))] : null,
                                          ),
                                          child: Stack(
                                            children: [
                                              // --- 1) image ---
                                              Positioned.fill(
                                                bottom: isSelected ? 0 : 10,
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(24),
                                                  child: Image.asset(examFoodItem[index]['image'], fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.person, size: 60, color: AppPalette.fg(Colors.blue))),
                                                ),
                                              ),
                                              // --- 3) radio ---
                                              Positioned(top: 5, right: 5, child: Container(height: 22, width: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isColor, width: highlighted ? 6 : 2))))
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const Spacer(),
                                // ===== 5) button =====
                                _buildBottomButton(context),
                              ],
                            ),
                            if (_isChecked) ...[Positioned(left: 0, right: 0, bottom: 80, child: _buildFeedbackBanner(context,  _selectedIndex == _correctIndex))],
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
  // ===== green/red feedback banner shown after checking =====
  Widget _buildFeedbackBanner(BuildContext context, bool isCorrect) {
    final Color bg = isCorrect ? AppPalette.auto(Color(0xFFDCFCE7)) : AppPalette.auto(Color(0xFFFEE2E2));
    final Color fg = isCorrect ? AppPalette.auto(Color(0xFF16A34A)).withValues(alpha: 0.8) : AppPalette.auto(Color(0xFFDC2626)).withValues(alpha: 0.8);
    final Color sc = isCorrect ? AppPalette.auto(Color(0xFF16A34A)).withValues(alpha: 0.9) : AppPalette.auto(Color(0xFFDC2626)).withValues(alpha: 0.9);
    final String correctLabel = '${examFoodItem[_correctIndex]['id'] ?? ''}';

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
              ),
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
    final AppLocalizations loc = AppLocalizations.of(context)!;

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
    final String label = _isChecked ? loc.translate('next_question') : loc.translate('check_answer_btn');
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
          children: [
            Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18, color: fg),
          ],
        ),
      ),
    );
  }
}
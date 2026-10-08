import 'package:flutter/material.dart';
import 'package:signlang/components/log/createProfile.dart';
import 'package:signlang/components/log/nameLog/nameLogItem.dart';
import 'package:signlang/components/log/onboardingProgress.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/statistics_service.dart';

import 'package:signlang/services/theme_service.dart';
import 'package:signlang/services/onboarding_answers.dart';
class HowLong extends StatefulWidget {
  const HowLong({super.key});

  @override
  State<HowLong> createState() => _HowLongState();
}

class _HowLongState extends State<HowLong> {
  int _selectedIndex = -1;

  void _handleValidation() async {
    if(_selectedIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('please_select')),
          backgroundColor: AppPalette.bg(Color(0xFFD32F2F)), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
      return;
    }

    // Map selection to minutes: 0->5, 1->10, 2->15, 3->20
    final minutes = (5 + (_selectedIndex * 5));
    StatisticsService.instance.setDailyGoal(minutes);
    await OnboardingAnswers.saveDailyGoal(_selectedIndex);
    if (!mounted) return;

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateProfile()));
  }

  @override
  Widget build(BuildContext context) {
    final howLongData = HowLongData(context: context);
    final howLongItem = howLongData.storeByHowLong['0'] ?? [];

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ===== 1) back =====
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.arrow_back_outlined))
                      ),
                      const SizedBox(width: 20),
                      const OnboardingProgress(currentStep: 2),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ===== 2) text =====
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('how_long'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.translate('how_long_sub'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400))
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ===== 3) click to cards =====
                  Column(
                    children: List.generate(howLongItem.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildHowLongItem(context, howLongItem[index], isActive: _selectedIndex == index, onTap: () { setState(() { _selectedIndex =index;}); })
                      );
                    }),
                  ),

                  const Spacer(),

                  // ===== 4) button =====
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _handleValidation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedIndex == -1 ? AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1) : AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), foregroundColor: AppPalette.fg(Colors.white),
                        elevation: _selectedIndex == -1 ? 0 : 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                        side: BorderSide(width: 1, color: _selectedIndex == -1 ? AppPalette.border(Colors.black12) : AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2))
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.translate('continue'),
                        style: TextStyle(fontWeight: FontWeight.w600, color: _selectedIndex == -1 ? AppPalette.fg(Colors.blue[700]!) : AppPalette.fg(Colors.blue[900]!))
                      )
                    ),
                  )
                ],
              ),
            )
          ),
        ),
      ),
    );
  }
}

// ======================== build ========================
Widget _buildHowLongItem(BuildContext context, Map<String, dynamic> item, {required bool isActive, required VoidCallback onTap}) {

  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppPalette.border(Color(0xFF4A7FD0)) : Colors.transparent, width: 1.5),
        boxShadow: [BoxShadow(color: isActive ? AppPalette.shadow(Color(0xFF42A5F5)).withOpacity(0.9) : Colors.transparent, blurRadius: 15, offset: const Offset(0, 4))]
      ),
      child: Row(
        children: [
          Image.asset(
            item['image'], width: 30, height: 30, color: isActive ? AppPalette.fg(Color(0xFF039BE5)) : AppPalette.fg(Color(0xFF81D4FA)),
            errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 30, color: AppPalette.fg(Colors.grey))
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['test'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isActive ? AppPalette.fg(Colors.black) : AppPalette.fg(Colors.black87))),
                Text(item['title'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: isActive ? AppPalette.fg(Colors.grey[800]!) : AppPalette.fg(Colors.grey[500]!)))
              ],
            ),
          ),

          Container(
            height: 24, width: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isActive ? AppPalette.border(Color(0xFF4A7FD0)) : AppPalette.border(Colors.black12), width: isActive ? 6 : 2)),
          )
        ],
      ),
    ),
  );
}
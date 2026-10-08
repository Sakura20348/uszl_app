import 'package:flutter/material.dart';
import 'package:signlang/components/lessonProgress/selectOneIllustration.dart';
import 'package:signlang/components/log/onboardingProgress.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/push_service.dart';

import 'package:signlang/services/theme_service.dart';
class NotificationBell extends StatefulWidget{
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationState();
}

class _NotificationState extends State<NotificationBell> {

  void _handleValidation() async {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectOneIllustration()));
  }

  // "Enable notifications": the system asks the user, then onboarding continues
  Future<void> _handleEnable() async {
    await PushService.requestPermission();
    _handleValidation();
  }

  // "Later": don't ask again right after login
  Future<void> _handleLater() async {
    await PushService.skipPermission();
    _handleValidation();
  }

  @override
  Widget build(BuildContext context) {
    const String ImagePath = 'web/images/notification_bell.png';
    return Scaffold(
      resizeToAvoidBottomInset: false, // no text field here: a closing keyboard must not squeeze the page
      body: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])
          ),
          child: SafeArea(
            // scrolls on small screens instead of overflowing; Spacer still pushes the buttons down on tall ones
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                  child: IntrinsicHeight(
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
                            const OnboardingProgress(currentStep: 4),
                          ],
                        ),
                        // ===== 2) image =====
                        const SizedBox(height: 40), Image.asset(ImagePath, height: 286, width: 240), const SizedBox(height: 12),
                        // ===== 3) text =====
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppLocalizations.of(context)!.translate('allow_notifications'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                            const SizedBox(height: 6),
                            Text(AppLocalizations.of(context)!.translate('allow_notifications_sub'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.black54)))
                          ],
                        ),

                        const Spacer(),

                        // ===== 4) button notification =====
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleEnable,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                              shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Text(AppLocalizations.of(context)!.translate('enable_notifications'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.blue[900]!))),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ===== 5) button =====
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleLater,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.bg(Colors.grey).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Colors.grey).withValues(alpha: 0.6),
                              side: BorderSide(width: 1, color: AppPalette.border(Colors.grey).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Text(AppLocalizations.of(context)!.translate('enable_notifications_sub'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
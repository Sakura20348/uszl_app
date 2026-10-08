import 'package:flutter/material.dart';
import 'package:signlang/components/log/login/phoneLogin.dart';
import 'package:signlang/components/log/whyUzsl.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class WelcomePage extends StatefulWidget{
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {

  void _handleValidation() async { if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => const WhyUzsl())); }

  void _handleValidationLogin() async { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PhoneLogin())); }

  @override
  Widget build(BuildContext context) {
    const String ImagePath = 'web/images/uzbek_sign_language.png';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ===== 1) image =====
                const SizedBox(height: 100), Image.asset(ImagePath, height: 264), const SizedBox(height: 12),
                // ===== 2) text =====
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('welcome_uzsl'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.black).withValues(alpha: 0.5))),
                      const SizedBox(height: 5),
                      Text(AppLocalizations.of(context)!.translate('welcome_uzsl_sub'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30))
                    ]
                  )
                ),

                const Spacer(),

                // ===== 3) button =====
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _handleValidation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                      side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(AppLocalizations.of(context)!.translate('start'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.blue[900]!))),
                  ),
                ),
                const SizedBox(height: 12),
                // ===== 4) click to login =====
                SizedBox(
                  width: double.infinity, height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('start_sub'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey))),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _handleValidationLogin,
                        child: Text(AppLocalizations.of(context)!.translate('log_in'), style: TextStyle(color: AppPalette.fg(Color(0xFF4A7FD0)), fontSize: 13, fontWeight: FontWeight.w400))
                      )
                    ],
                  ),
                )
              ],
            )
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/components/log/langguageChoose.dart';
import 'package:signlang/components/web/update/updateSheet.dart';
import 'package:signlang/main.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:signlang/services/theme_service.dart';
class SplashScreenUI extends StatefulWidget {
  const SplashScreenUI({super.key});

  @override
  State<SplashScreenUI> createState() => _SplashScreenUIState();
}

class _SplashScreenUIState extends State<SplashScreenUI> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),
              // --- 1) ---
              Column(
                children: [
                  Image.asset('web/images/sign_lang_wrap.png', width: 120, height: 100, color: AppPalette.fg(Colors.blue[600]!)),
                  const SizedBox(height: 24),
                  Text('Uzbek Sign\nLanguage', textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppPalette.fg(Colors.black))),
                ],
              ),
              // --- 2) ---
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Powered by ', style: TextStyle(color: AppPalette.fg(Colors.grey[600]!), fontSize: 13)),
                    const SizedBox(width: 6),
                    Image.asset('web/images/zehnmind.png', width: 20, height: 20),
                    const SizedBox(width: 6),
                    Text('zehnmind.ai', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppPalette.fg(Colors.black87))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Splash logic — the ONLY place navigation happens.
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); _navigateToNext(); }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // 1) check for a required update
    final needsUpdate = await _checkForUpdate();
    if (!mounted) return;

    if (needsUpdate) {
      UpdateSheet.show(
        context,
        onUpdate: () async {
          try {
            return await launchUrl(
              Uri.parse('https://play.google.com/store/apps/details?id=com.yourapp'),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) { return false; }
        },
      );
      return;
    }

    // 2) normal flow
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!mounted) return;

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => isLoggedIn ? const MainWrapper(initialTab: 0) : const LanguageChoose()));
  }

  Future<bool> _checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // e.g. "1.2.0"
      // TODO: fetch min version from backend and compare.
      // return _isOlder(currentVersion, minVersion);
      return false; // return true to test the update sheet
    } catch (_) { return false; }
  }

  @override
  Widget build(BuildContext context) { return const SplashScreenUI(); }
}
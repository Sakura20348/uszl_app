import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/components/log/login/emailAuth.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/main.dart';

import 'package:signlang/services/theme_service.dart';
class LanguageChoose extends StatefulWidget{
  const LanguageChoose({super.key});

  @override
  State<LanguageChoose> createState() => _LanguageChooseState();
}
class _LanguageChooseState extends State<LanguageChoose> {
  String _selectedLang = 'en';

  Future<void> _saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', langCode);
    await prefs.setBool('isLanguageSelected', true);
  }

  void _handleValidation() async {
    await _saveLanguage(_selectedLang);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    MyApp.of(context).setLocale(Locale(_selectedLang));
    // (avoids the '_history.isNotEmpty' assertion).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.push(MaterialPageRoute(builder: (context) => const EmailAuth()));
    });
  }

  @override
  Widget build(BuildContext context){
    const String uzbekFlagPath = 'web/images/uzbek_flag.png';
    const String rusFlagPath = 'web/images/rus_flag.png';
    const String engFlagPath = 'web/images/eng_flag.png';
    final AppLocalizations loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // ===== 1) text =====
                Text(loc.translate('choose_lang'), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppPalette.fg(Colors.black), letterSpacing: -0.5)), const SizedBox(height: 8),
                // ===== 2) text =====
                Text(loc.translate('choose_lang_sub'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.black54))), const SizedBox(height: 32),
                // ===== 3) other lang =====
                _buildLanguageCard(langCode: 'uz', title: 'Uzbek', image: uzbekFlagPath), const SizedBox(height: 12),
                _buildLanguageCard(langCode: 'ru', title: 'Русский', image: rusFlagPath), const SizedBox(height: 12),
                _buildLanguageCard(langCode: 'en', title: 'English', image: engFlagPath), const Spacer(),
                // ===== 4) button =====
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: _handleValidation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                      side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(loc.translate('continue'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.blue[900]!))),
                  ),
                ),
              ],
            ),
          )
        ),
      ),
    );
  }

  // ======================== build ========================
  Widget _buildLanguageCard({
    required String langCode,
    required String title,
    required String image,
  }) {
    final bool isSelected = _selectedLang == langCode;

    return GestureDetector(
      onTap: () { setState(() { _selectedLang = langCode; }); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? AppPalette.border(Color(0xFF4A7FD0)) : Colors.transparent, width: 1.5),
          boxShadow: [BoxShadow(color: isSelected ? AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9) : Colors.transparent, blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Image.asset(image, width: 32, height: 32, fit: BoxFit.contain), const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.w400, color: isSelected ? AppPalette.fg(Color(0xFF1A237E)).withValues(alpha: 0.9) : AppPalette.fg(Colors.black87))),
            ),
            Container(
              height: 24, width: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppPalette.border(Color(0xFF4A7FD0)) : AppPalette.border(Colors.black12), width: isSelected ? 6 : 2)),
            ),
          ],
        ),
      ),
    );
  }
}
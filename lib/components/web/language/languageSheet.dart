import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/l10n/app_localizations.dart';
import '../../../main.dart';

import 'package:signlang/services/theme_service.dart';
class LanguageSheet extends StatefulWidget{
  const LanguageSheet({super.key});

  @override
  State<LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<LanguageSheet> with SingleTickerProviderStateMixin {
  int tabIndex = -1;
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  Future<void> _loadSavedLanguage() async {
    final savedIndex = await LanguageStorage.load();
    if (mounted) { setState(() { tabIndex = savedIndex ?? 0; }); }
  }

  void _changeLanguage(Locale locale) { MyApp.of(context).setLocale(locale); }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context){
    const String ImageTranslate = 'web/icons/translate.png';
    final AppLocalizations loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 40),
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFF81D4FA)).withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFB3E5FC)).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF81D4FA)).withOpacity(0.9), blurRadius: 15, offset: Offset(0, -6))]
      ),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFF81D4FA)).withOpacity(0.9), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 18),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
                    child: Image.asset(ImageTranslate, width: 32, height: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(loc.translate('change_language'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(loc.translate('change_language_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400))
                ],
              ),
              const SizedBox(height: 16),
              _langTile('web/images/uzbek_flag.png', index: 0, 'Uzbek', const Locale('uz')),
              const SizedBox(height: 12,),
              _langTile('web/images/eng_flag.png', index: 1, 'English', const Locale('en')),
              const SizedBox(height: 12,),
              _langTile('web/images/rus_flag.png', index: 2, 'Русский', const Locale('ru')),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget _langTile(String image, String name, Locale locale, {required int index}) {
    final bool isActive = tabIndex == index;
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppPalette.bg(Color(0xFF1565C0)).withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: isActive ? AppPalette.shadow(Color(0xFF1565C0)).withOpacity(0.30) : Colors.transparent, blurRadius: 20)]
      ),
      child: ListTile(
        leading: Image.asset(image, width: 34, height: 34),
        title: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        onTap: () async {
          setState(() { tabIndex = index; });
          await LanguageStorage.save(index);
          if (!mounted) return;
          _changeLanguage(locale);
          Navigator.pop(context, index);
        },
      ),
    );
  }
}

class LanguageStorage {
  static const _key = 'selected_language_index';

  static Future<void> save(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }

  static Future<int?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key);
  }
}
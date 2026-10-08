import 'package:flutter/material.dart';
import 'package:signlang/services/account_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../log/langguageChoose.dart';

import 'package:signlang/services/theme_service.dart';
class LogOutDelete extends StatefulWidget{
  const LogOutDelete({super.key});

  @override
  State<LogOutDelete> createState() => _LogOutDeleteState();
}

class _LogOutDeleteState extends State<LogOutDelete> with SingleTickerProviderStateMixin {
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

// ================================ Button ==================================
  // In your Profile screen
  void _logout() async {
    // Waiting results are sent, pushes stop, and this person's data is removed from the phone
    await AccountService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setInt('tabIndex', 0);
    if (!mounted) return;

    Navigator.pushAndRemoveUntil( context, MaterialPageRoute(builder: (_) => const LanguageChoose()), (route) => false );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    const ImageLogOutDelete = 'web/icons/door_open_alt.png';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 40),
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFFEF9A9A)).withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFFFCDD2)).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFFEF9A9A)).withOpacity(0.9), blurRadius: 15, offset: Offset(0, -6))]
      ),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE57373)).withOpacity(0.9), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 18),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFFFEBEE)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white),), borderRadius: BorderRadius.circular(18)),
                    child: Image.asset(ImageLogOutDelete, color: AppPalette.fg(Colors.red)),
                  ),
                  const SizedBox(height: 12),
                  Text(loc.translate('want_log_out'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24, color: AppPalette.fg(Color(0xFF0F172A)))),
                  const SizedBox(height: 8),
                  Text(loc.translate('want_log_out_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: AppPalette.fg(Color(0xFF0F172A)).withOpacity(0.7))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.bg(Color(0xFFEF9A9A)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                        shadowColor: AppPalette.shadow(Color(0xFFB71C1C)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFFB71C1C)).withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                      ),
                      child: Text(loc.translate('delete_account'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.bg(Color(0xFFEEEEEE)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                        shadowColor: AppPalette.shadow(Color(0xFF212121)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF212121)).withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text(loc.translate('cancel'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
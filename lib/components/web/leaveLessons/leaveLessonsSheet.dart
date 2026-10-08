import 'package:flutter/material.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class LeaveLessonsSheet extends StatefulWidget {
  const LeaveLessonsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context, isDismissible: false, backgroundColor: AppPalette.bg(Color(0xFFEDEDED)),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => LeaveLessonsSheet(),
    );
  }

  @override
  State<LeaveLessonsSheet> createState() => _LeaveLessonsSheetState();
}

class _LeaveLessonsSheetState extends State<LeaveLessonsSheet> with SingleTickerProviderStateMixin {
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
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String ImageBookOpen = 'web/icons/book_open.png';
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), height: 480,
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFF80CBC4)).withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFB2DFDB)).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF80CBC4)).withOpacity(0.7), blurRadius: 15, offset: Offset(0, -6))]
      ),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFF80CBC4)).withOpacity(0.9), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppPalette.bg(Color(0xFF8BC34A)).withOpacity(0.1), borderRadius: BorderRadius.circular(22), border: Border.all(width: 1, color: AppPalette.border(Color(0xFF8BC34A)).withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF8BC34A)).withOpacity(0.35), blurRadius: 15)]
                ),
                child: Image.asset(ImageBookOpen, width: 44, height: 44),
              ),
              const SizedBox(height: 20),
              Text(loc.translate('leave_lessons'), textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))),
              const SizedBox(height: 6),
              Text(loc.translate('leave_lessons_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppPalette.fg(Color(0xFF0F172A)).withOpacity(0.7))),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                    shadowColor: AppPalette.shadow(Color(0xFF1A237E)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(loc.translate('continue'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.white))),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.bg(Color(0xFFFFEBEE)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.grey), elevation: 6,
                    shadowColor: AppPalette.shadow(Color(0xFFB71C1C)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFFB71C1C)).withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(loc.translate('Leaving the class'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
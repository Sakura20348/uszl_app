import 'package:flutter/material.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class NoInternetSheet extends StatefulWidget {
  final VoidCallback onRetry;
  const NoInternetSheet({super.key, required this.onRetry});

  static Future<void> show(BuildContext context, {required VoidCallback onRetry}) {
    return showModalBottomSheet(
      context: context, constraints: const BoxConstraints(maxWidth: 560), isDismissible: false, isScrollControlled: true, backgroundColor: AppPalette.bg(Color(0xFFEDEDED)),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => NoInternetSheet(onRetry: onRetry),
    );
  }

  @override
  State<NoInternetSheet> createState() => _NoInternetSheetState();
}

class _NoInternetSheetState extends State<NoInternetSheet> with SingleTickerProviderStateMixin {
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
    const String ImageNoInternet = 'web/icons/no_internet.png';
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFF80CBC4)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFB2DFDB)).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF80CBC4)).withValues(alpha: 0.7), blurRadius: 15, offset: Offset(0, -6))]
      ),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFF80CBC4)).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppPalette.bg(Color(0xFFFFEB3B)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(22), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFFFEB3B)).withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFFFFEB3B)).withValues(alpha: 0.35), blurRadius: 15)]
                ),
                child: Image.asset(ImageNoInternet, width: 44, height: 44),
              ),
              const SizedBox(height: 20), Text(loc.translate('no_internet'), textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))),
              const SizedBox(height: 6), Text(loc.translate('no_internet_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppPalette.fg(Color(0xFF0F172A)).withValues(alpha: 0.7))),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: widget.onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Color(0xFF1A237E)).withValues(alpha: 0.9),
                    side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(loc.translate('try_again'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.white))),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.bg(Color(0xFFECEFF1)).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.grey), elevation: 6,
                    shadowColor: AppPalette.shadow(Color(0xFF263238)).withValues(alpha: 0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF263238)).withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(loc.translate('close'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
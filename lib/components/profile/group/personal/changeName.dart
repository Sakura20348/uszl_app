import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class ChangeName extends StatefulWidget {
  final String initialName;
  const ChangeName({super.key, required this.initialName});

  @override
  State<ChangeName> createState() => _ChangeNameState();
}

class _ChangeNameState extends State<ChangeName> with SingleTickerProviderStateMixin {
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;
  late AnimationController _animController;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const String ImageUser = 'web/icons/user.png';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFFF5F5F5)).withOpacity(0.1), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFECEFF1)).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFFF5F5F5)).withOpacity(0.9), blurRadius: 15, offset: const Offset(0, -6))],
      ),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFEEEEEE)).withOpacity(0.9), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppPalette.bg(Colors.black).withOpacity(0.1), border: Border.all(width: 2, color: AppPalette.border(Colors.white).withOpacity(0.9)), borderRadius: BorderRadius.circular(20)),
                  child: Image.asset(ImageUser, width: 32, height: 32),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(loc.translate('edit_name'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A))))),
              const SizedBox(height: 8),
              Center(
                child: Text(loc.translate('edit_name_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppPalette.fg(Color(0xFF0F172A)).withOpacity(0.7))),
              ),
              const SizedBox(height: 22),
              Text(loc.translate('full_name'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF1E293B)))),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  filled: true, fillColor: AppPalette.bg(Colors.white).withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.bg(Color(0xFFBBDEFB)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                    shadowColor: AppPalette.shadow(Color(0xFF0D47A1)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF0D47A1)).withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(loc.translate('save'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 40)
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class UpdateSheet extends StatefulWidget {
  final Future<bool> Function() onUpdate; // return true if update succeeded/left

  const UpdateSheet({super.key, required this.onUpdate});

  static Future<void> show(BuildContext context, {required Future<bool> Function() onUpdate}) {
    return showModalBottomSheet(
      context: context, constraints: const BoxConstraints(maxWidth: 560),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppPalette.bg(Color(0xFFEDEDED)),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => PopScope( canPop: false, child: UpdateSheet(onUpdate: onUpdate) ),
    );
  }

  @override
  State<UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<UpdateSheet> with SingleTickerProviderStateMixin {
  bool _pressed = false;
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

  Future<void> _handleUpdate() async {
    final ok = await widget.onUpdate();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFF81D4FA)).withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFB3E5FC)).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF81D4FA)).withOpacity(0.7), blurRadius: 15, offset: Offset(0, -6))]
      ),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFF81D4FA)).withOpacity(0.9), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppPalette.bg(Color(0xFF2196F3)).withOpacity(0.1), borderRadius: BorderRadius.circular(22), border: Border.all(width: 1, color: AppPalette.border(Color(0xFF2196F3)).withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF2196F3)).withOpacity(0.35), blurRadius: 15)]
                ),
                child: Icon(Icons.download, size: 44, color: AppPalette.fg(Color(0xFF0D47A1))),
              ),
              const SizedBox(height: 20),
              Text(loc.translate('update_available'), textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))),
              const SizedBox(height: 6),
              Text(loc.translate('update_available_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppPalette.fg(Color(0xFF0F172A)).withOpacity(0.7))),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 56,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) { setState(() => _pressed = false); _handleUpdate(); },
                  onTapCancel: () => setState(() => _pressed = false),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppPalette.bg(Color(0xFF4A7FD0)).withOpacity(0.2), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withOpacity(0.2)),
                        boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF1A237E)).withOpacity(0.70), blurRadius: 15, offset: Offset(0, 6))]
                    ),
                    child: Text(loc.translate('update_now'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.white))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
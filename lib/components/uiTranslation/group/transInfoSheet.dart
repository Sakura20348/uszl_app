import 'package:flutter/material.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/theme_service.dart';

/// Bottom sheet for translation modes that can't be opened: not built yet, or locked until a lesson is done.
class TransInfoSheet extends StatelessWidget {
  final String titleKey;
  final String subKey;
  final String buttonKey;
  final IconData icon;
  /// Optional illustration (e.g. the "under construction" character); falls back to [icon].
  final String? image;
  final VoidCallback? onPressed;

  const TransInfoSheet({super.key, required this.titleKey, required this.subKey, this.buttonKey = 'continue', this.icon = Icons.construction_rounded, this.image, this.onPressed});

  static Future<void> show(BuildContext context, {required String titleKey, required String subKey, String buttonKey = 'continue', IconData icon = Icons.construction_rounded, String? image, VoidCallback? onPressed}) {
    return showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => TransInfoSheet(titleKey: titleKey, subKey: subKey, buttonKey: buttonKey, icon: icon, image: image, onPressed: onPressed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    const Color blue = Color(0xFF4A7FD0);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 12), padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewPadding.bottom * 0.5),
      decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: c.glow.withValues(alpha: 0.9), blurRadius: 15)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 16),
          // ===== illustration =====
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 230, height: 150, decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE8F1FD)), borderRadius: BorderRadius.circular(90))),
                if (image != null)
                  Image.asset(image!, height: 190, errorBuilder: (_, _, _) => _iconArt(blue))
                else
                  _iconArt(blue),
                // little decorations like the design
                Positioned(left: 30, top: 30, child: Icon(Icons.star_rounded, size: 22, color: AppPalette.fg(const Color(0xFFFFB300)))),
                Positioned(right: 34, top: 70, child: Icon(Icons.star_rounded, size: 18, color: AppPalette.fg(const Color(0xFFFFB300)))),
                Positioned(left: 44, bottom: 40, child: _dot(const Color(0xFF34C38F), 10)),
                Positioned(right: 48, bottom: 30, child: _dot(const Color(0xFF8E7CF0), 10)),
                Positioned(right: 70, top: 26, child: _dot(blue, 7)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(loc.translate(titleKey), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 8),
          Text(loc.translate(subKey), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: c.subText)),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); onPressed?.call(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(loc.translate(buttonKey), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconArt(Color blue) => Container(
    width: 110, height: 110,
    decoration: BoxDecoration(color: AppPalette.bg(blue), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppPalette.shadow(blue).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))]),
    child: Icon(icon, size: 56, color: Colors.white),
  );

  Widget _dot(Color color, double size) => Container(width: size, height: size, decoration: BoxDecoration(color: AppPalette.bg(color), borderRadius: BorderRadius.circular(3)));
}

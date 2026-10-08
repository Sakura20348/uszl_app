import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';

/// Bottom sheet for one achievement.
/// Closed: shows the task that opens it and how far the person is. Opened: congratulation + share.
class AwardsInfo extends StatefulWidget{
  final Map<String, dynamic> item;
  const AwardsInfo({super.key, required this.item});

  @override
  State<AwardsInfo> createState() => _AwardsInfoState();
}

class _AwardsInfoState extends State<AwardsInfo> with SingleTickerProviderStateMixin {
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;
  late Animation<double> _badgePop;
  late AnimationController _animController;

  static const List<double> _greyMatrix = [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 0.6, 0];

  @override
  void initState() {
    super.initState();
    final bool isNew = widget.item['isNew'] ?? false;
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: isNew ? 1100 : 700));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    // a just-opened achievement "pops" open; others simply appear
    _badgePop = isNew
        ? Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.elasticOut)))
        : const AlwaysStoppedAnimation(1.0);
    _animController.forward();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  void _handleShare() {
    final loc = AppLocalizations.of(context)!;
    final title = widget.item['titleKey'] ?? '';
    SharePlus.instance.share(ShareParams(text: '${loc.translate('share_message')} "$title" 🔥\n\nhttps://play.google.com/store/apps/details?id=com.example.signlang'));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    final bool unlocked = widget.item['unlocked'] ?? false;
    final bool isNew = widget.item['isNew'] ?? false;
    final String image = widget.item['image'] ?? 'web/images/fire.png';
    final String title = widget.item['titleKey'] ?? '';
    final String task = widget.item['subKey'] ?? '';
    final String doneText = widget.item['subTitleKey'] ?? '';
    final int target = widget.item['target'] ?? 1;
    final int progress = ((widget.item['progress'] ?? 0) as int).clamp(0, target);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      decoration: BoxDecoration(
        color: unlocked ? AppPalette.bg(Color(0xFF81D4FA)).withValues(alpha: 0.1) : AppPalette.bg(Color(0xFFB0BEC5)).withValues(alpha: 0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(width: 1, color: unlocked ? AppPalette.border(Color(0xFFB3E5FC)).withValues(alpha: 0.2) : AppPalette.border(Color(0xFFCFD8DC)).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: unlocked ? AppPalette.shadow(Color(0xFF81D4FA)).withValues(alpha: 0.9) : AppPalette.shadow(Color(0xFFB0BEC5)).withValues(alpha: 0.9), blurRadius: 15, offset: const Offset(0, -6))],
      ),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: unlocked ? AppPalette.bg(Color(0xFF4FC3F7)).withValues(alpha: 0.9) : AppPalette.bg(Color(0xFF90A4AE)).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 30),
              // ===== 1) badge =====
              ScaleTransition(
                scale: _badgePop,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 140, height: 140, decoration: BoxDecoration(color: unlocked ? AppPalette.bg(Color(0xFFE1F5FE)).withValues(alpha: 0.3) : AppPalette.bg(Color(0xFFECEFF1)).withValues(alpha: 0.3), shape: BoxShape.circle)),
                    ColorFiltered(
                      colorFilter: unlocked ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply) : const ColorFilter.matrix(_greyMatrix),
                      child: image.isNotEmpty ? Image.asset(image, width: 100, height: 100) : Icon(Icons.stars, size: 100, color: AppPalette.fg(unlocked ? Colors.amber : Colors.grey)),
                    ),
                    if (!unlocked)
                      Positioned(
                        right: 8, bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppPalette.bg(Colors.white), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.3), blurRadius: 8)]),
                          child: Icon(Icons.lock, size: 20, color: AppPalette.fg(Colors.grey[700]!)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ===== 2) title + status =====
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))),
              const SizedBox(height: 8),
              if (unlocked) ...[
                Text(doneText, textAlign: TextAlign.center, style: TextStyle(color: AppPalette.fg(Color(0xFF0F172A)).withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.w400)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statusChip(icon: Icons.lock_open, text: loc.translate('opened'), bg: Colors.green, fg: Colors.green[900]!),
                    if (isNew) ...[const SizedBox(width: 8), _statusChip(icon: Icons.auto_awesome, text: loc.translate('ach_new'), bg: Colors.amber, fg: Colors.orange[900]!)],
                  ],
                ),
                const SizedBox(height: 16),
                _messageCard(
                  icon: Image.asset('web/icons/info_yellow.png', width: 28, height: 28, color: AppPalette.fg(Colors.orange)),
                  title: loc.translate('important'), body: loc.translate('important_sub'),
                  tint: const Color(0xFFFFCC80), border: const Color(0xFFFFC107), iconBg: const Color(0xFFFFF176), iconBorder: Colors.yellow,
                ),
                const SizedBox(height: 16),
                _button(text: loc.translate('great'), onPressed: () => Navigator.pop(context), bg: const Color(0xFF90CAF9), shadow: const Color(0xFF0D47A1)),
                const SizedBox(height: 10),
                _button(text: loc.translate('share_achievement'), icon: Icons.share, onPressed: _handleShare, bg: const Color(0xFFEEEEEE), shadow: const Color(0xFF212121)),
              ] else ...[
                _statusChip(icon: Icons.lock, text: loc.translate('locked'), bg: Colors.grey, fg: Colors.grey[800]!),
                const SizedBox(height: 16),
                // ===== 3) what to do to open it =====
                _messageCard(
                  icon: Icon(Icons.flag_rounded, size: 28, color: AppPalette.fg(const Color(0xFF1E88E5))),
                  title: loc.translate('ach_how_to'), body: task,
                  tint: const Color(0xFF90CAF9), border: const Color(0xFF42A5F5), iconBg: const Color(0xFFBBDEFB), iconBorder: const Color(0xFF64B5F6),
                  footer: _progressBar(progress, target),
                ),
                const SizedBox(height: 24),
                _button(text: loc.translate('keep_going'), onPressed: () => Navigator.pop(context), bg: const Color(0xFFEEEEEE), shadow: const Color(0xFF212121)),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip({required IconData icon, required String text, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppPalette.bg(bg).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppPalette.fg(fg)), const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppPalette.fg(fg))),
        ],
      ),
    );
  }

  Widget _messageCard({required Widget icon, required String title, required String body, required Color tint, required Color border, required Color iconBg, required Color iconBorder, Widget? footer}) {
    return Container(
      padding: const EdgeInsets.all(16), width: double.infinity,
      decoration: BoxDecoration(
        color: AppPalette.bg(tint).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(border).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(tint).withValues(alpha: 0.9), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppPalette.bg(iconBg).withValues(alpha: 0.6), border: Border.all(width: 1, color: AppPalette.border(iconBorder)), borderRadius: BorderRadius.circular(15)),
                child: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(body, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 14), footer],
        ],
      ),
    );
  }

  Widget _progressBar(int progress, int target) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: target > 0 ? progress / target : 0),
              duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(value: value, minHeight: 10, backgroundColor: AppPalette.bg(const Color(0xFFD6E4F0)), valueColor: AlwaysStoppedAnimation(AppPalette.fg(const Color(0xFF1E88E5)))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$progress/$target', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppPalette.fg(const Color(0xFF1565C0)))),
      ],
    );
  }

  Widget _button({required String text, required VoidCallback onPressed, required Color bg, required Color shadow, IconData? icon}) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.bg(bg).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(shadow).withValues(alpha: 0.9),
          side: BorderSide(width: 1, color: AppPalette.border(shadow).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: AppPalette.fg(Colors.white), size: 22), const SizedBox(width: 8)],
            Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.white))),
          ],
        ),
      ),
    );
  }
}

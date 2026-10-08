import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/uiTextBooks/skeleton/skeleton.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
/// One notification opened from the list (or from a tapped push):
/// an unlocked achievement, or a message sent from the dashboard.
class NotificationModal extends StatefulWidget{
  final AppNotification notification;
  const NotificationModal({super.key, required this.notification});

  @override
  State<NotificationModal> createState() => _NotificationState();
}

class _NotificationState extends State<NotificationModal> with SingleTickerProviderStateMixin {
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;
  late AnimationController _animController;
  bool _isLoading = true;

  bool get _isAchievement => widget.notification.type == 'achievement';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();

    _initData();
  }

  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() => _isLoading = false); } }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animController.dispose();
    super.dispose();
  }

  void _handleNext() {
    Navigator.pop(context);
    // Navigator.push(context, MaterialPageRoute(builder: (_) => const Textbooks()));
  }

  /// "05.10.2026 14:30"
  String _time(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.day)}.${two(time.month)}.${time.year} ${two(time.hour)}:${two(time.minute)}';
  }


  Widget _button(String label, VoidCallback onPressed, {bool primary = true}) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.2) : AppPalette.bg(Colors.grey).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
          shadowColor: primary ? AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9) : AppPalette.shadow(Colors.grey).withValues(alpha: 0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: AppPalette.fg(Colors.white))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final notification = widget.notification;
    const String imageFire = 'web/images/fire.png';
    const String imageMessage = 'web/icons/code.png';
    return SafeArea(
      top: false,
      child: _isLoading
        ? Padding(
          padding: const EdgeInsets.all(16),
          child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: NotificationSkeleton.buildSkeleton()),
        )
        : Padding(
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 70, height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5), color: AppPalette.bg(Color(0xFF00B8D4)).withValues(alpha: 0.9), border: Border.all(width: 0.5, color: AppPalette.border(Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _isAchievement ? Image.asset(imageFire, width: 142, height: 168) : Image.asset(imageMessage, width: 72, height: 72),
                  const SizedBox(height: 18),
                  if (_isAchievement) ...[
                    Text(loc.translate('new_achievement_opened'), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppPalette.fg(Colors.grey[700]!))),
                    const SizedBox(height: 6),
                  ],
                  Text(notification.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(_time(notification.createdAt), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppPalette.fg(Colors.grey[600]!))),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(notification.body, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: AppPalette.fg(Colors.grey[700]!))),
                  ],
                  const SizedBox(height: 30),
                  if (_isAchievement) ...[
                    _button(loc.translate('see_achievement'), _handleNext),
                    const SizedBox(height: 12),
                    _button(loc.translate('see_achievement_sub'), () => Navigator.pop(context), primary: false),
                  ] else
                    _button(loc.translate('close'), () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

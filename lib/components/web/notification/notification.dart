import 'package:signlang/services/app_loading.dart';
import 'package:signlang/services/notification_center.dart';

import 'package:flutter/material.dart';
import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/web/notification/notificationModal.dart';
import '../../../l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
/// Notifications from the server: what admins send from the dashboard (news, reminders)
/// and the app's own (unlocked achievements).
class NotificationScreen extends StatefulWidget {
  /// Opened from a tapped push: show this notification once the list has loaded
  final int? openNotificationId;
  const NotificationScreen({super.key, this.openNotificationId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<AppNotification> _items = [];
  // Opened once, the first time the list loads
  late int? _openId = widget.openNotificationId;

  @override
  void initState() { super.initState(); _initData(); }

  Future<void> _initData() async {
    await AppLoading.ready();
    List<AppNotification> items = [];
    // Not logged in (or the session ended): nothing to show
    if (await UzslApi.isLoggedIn()) {
      try {
        items = await UzslApi.notifications();
      } on ApiException catch (e) {
        items = _items;
        if (mounted && e.status != 401) showApiError(context, e, onRetry: _handleRefresh);
      }
    }
    if (!mounted) return;
    setState(() { _items = items; _isLoading = false; });

    final openId = _openId;
    _openId = null;
    if (openId != null) {
      final match = items.where((n) => n.id == openId);
      if (match.isNotEmpty) _openNotification(match.first);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await _initData();
  }

  Future<void> _markAllRead() async {
    if (_items.every((n) => n.isRead)) return;
    try {
      await UzslApi.markAllRead();
      if (mounted) setState(() { for (final n in _items) { n.isRead = true; } });
      NotificationCenter.refresh(alert: false);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e, onRetry: _markAllRead);
    }
  }

  Future<void> _openNotification(AppNotification item) async {
    final Widget page = NotificationModal(notification: item);

    await showModalBottomSheet(
      context: context,
      enableDrag: true,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9,
        builder: (context, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            decoration: BoxDecoration(
              color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
              boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)]
            ),
            child: SingleChildScrollView(controller: controller, child: page),
          ),
        ),
      ),
    );

    if (!mounted || item.isRead) return;
    setState(() => item.isRead = true);
    try {
      await UzslApi.markRead(item.id);
      NotificationCenter.refresh(alert: false);
    } on ApiException {
      // Shown as read now; the server marks it next time
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // ===== top bar: back + mark-all-read =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleButton(Icons.arrow_back, () => Navigator.pop(context)),
                      _circleButton(Icons.done_all, _markAllRead),
                    ],
                  ),
                ),
                Expanded( child: _isLoading ? const Center(child: CircularProgressIndicator()) : ( _items.isEmpty ? _emptyState(loc) : _listState(loc) )),
              ],
            ),
          )
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: AppPalette.fg(Color(0xFF334155)), size: 22),
      ),
    );
  }

  // ===== Image 1: empty state =====
  Widget _emptyState(AppLocalizations loc) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Image.asset('web/images/not_notification.png', height: 260),
        const SizedBox(height: 24),
        Text(
          loc.translate('notif_empty_title'), textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A))),
        ),
        const SizedBox(height: 10),
        Text(loc.translate('notif_empty_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.grey[600]!))),
      ],
    );
  }

  // ===== Image 2: list state =====
  Widget _listState(AppLocalizations loc) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        const SizedBox(height: 8),
        Text(loc.translate('notifications'), style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A)))),
        const SizedBox(height: 8),
        Text(loc.translate('notifications_sub'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.grey[600]!))),
        const SizedBox(height: 16),
        ..._items.map(_notifCard),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _notifCard(AppNotification item) {
    final bool unread = !item.isRead;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openNotification(item),      // open, then mark read on return
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16),
              border: Border.all(width: 1, color: AppPalette.border(Colors.white)), boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.6), blurRadius: 12)],
            ),
            child: Row(
              children: [
                Container(
                  height: 60, width: 60,
                  decoration: BoxDecoration(
                    color: AppPalette.bg(Color(0xFFE3F2FD)).withValues(alpha: 0.7), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Image.asset(item.type == 'achievement' ? 'web/images/fire.png' : 'web/icons/code.png', width: 30, height: 30)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPalette.fg(Color(0xFF0F172A)))),
                      const SizedBox(height: 4),
                      Text(item.body, style: TextStyle(fontSize: 14, color: AppPalette.fg(Colors.grey[600]!)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(formatNotificationTime(item.createdAt), style: TextStyle(fontSize: 12, color: AppPalette.fg(Colors.grey[500]!))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (unread)
                  Container(height: 10, width: 10, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFEF4444)), shape: BoxShape.circle)),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

/// "05.10.2026 14:30"
String formatNotificationTime(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(time.day)}.${two(time.month)}.${time.year} ${two(time.hour)}:${two(time.minute)}';
}

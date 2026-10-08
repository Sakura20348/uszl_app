import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signlang/components/uiDictionary/nameDictionary/nameDictionary.dart';
import 'package:signlang/components/web/customSwitch/customSwitch.dart';
import 'package:signlang/components/web/loading/download.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class Download extends StatefulWidget {
  const Download({super.key});

  @override
  State<Download> createState() => _DownloadState();
}

class _DownloadState extends State<Download> {
  bool _isLoading = true;
  bool _onlyWifi = true;
  bool _autoUpdate = false;

  late var downloadItems = DownloadData(context: context).downloadItems;
  final Map<int, Timer> _timers = {};

  @override
  void initState() { super.initState(); _initData(); }

  @override
  void dispose() {
    for (final t in _timers.values) { t.cancel(); }
    super.dispose();
  }

  Future<void> _initData() async { await Future.delayed(const Duration(milliseconds: 800)); if (!mounted) return; setState(() { _isLoading = false; }); }

  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initData(); }

  // Tap handler: starts the download. Ignored if already downloading/completed.
  void _startDownload(int index) {
    final item = downloadItems[index];
    if (item['status'] != 'pending') return; // can't click if downloading/done
    setState(() { item['status'] = 'downloading'; item['progress'] = 0.0; });
    _timers[index]?.cancel();
    _timers[index] = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        double p = (item['progress'] as double) + 0.02; // 0 -> 100%
        if (p >= 1.0) { p = 1.0; item['status'] = 'completed'; timer.cancel(); _timers.remove(index); }
        item['progress'] = p;
      });
    });
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
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification n) => n.depth == 0,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _backButton(),
                    if (_isLoading)
                      const SizedBox(height: 600, child: Center(child: Padding(padding: EdgeInsets.only(top: 50), child: CircularProgressIndicator())))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(loc.translate('offline_download'), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))),
                          const SizedBox(height: 4),
                          Text(loc.translate('offline_download_sub'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.blueGrey).withOpacity(0.7))),
                          const SizedBox(height: 24),
                          _buildDownloadContent(loc),
                        ],
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(Icons.arrow_back_outlined, color: AppPalette.fg(Color(0xFF334155)), size: 22),
      ),
    );
  }

  Widget _buildDownloadContent(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < downloadItems.length; i++) _buildDownloadCard(i, downloadItems[i], loc),
        const SizedBox(height: 5),
        Text(loc.translate('settings'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSettingTile( loc.translate('only_wifi'), loc.translate('only_wifi_sub'), _onlyWifi, Icons.wifi, (val) => setState(() => _onlyWifi = val) ),
        const SizedBox(height: 12),
        _buildSettingTile( loc.translate('automatic_update'), loc.translate('automatic_update_sub'), _autoUpdate, Icons.refresh_rounded, (val) => setState(() => _autoUpdate = val) ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDownloadCard(int index, Map<String, dynamic> item, AppLocalizations loc) {
    final bool isDownloading = item['status'] == 'downloading';
    final bool isCompleted = item['status'] == 'completed';
    final double progress = item['progress'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFFBBDEFB)).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border(Colors.white), width: 1), boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF90CAF9)).withOpacity(0.9), blurRadius: 15)]
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(12)),
                child: Image.asset(item['image'], color: AppPalette.fg(Color(0xFF4A7FD0)), width: 24, height: 24, errorBuilder: (_, __, ___) => Icon(Icons.add, size: 24, color: AppPalette.fg(Colors.blue))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.translate(item['key']), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF1E293B)))),
                    Text(item['size'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.blueGrey).withOpacity(0.9))),
                  ],
                ),
              ),
              // The animated download button (replaces the old status icon).
              DownloadButton(status: item['status'] as String, onTap: () => _startDownload(index)),
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: progress, backgroundColor: AppPalette.bg(Color(0xFFE2E8F0)), color: AppPalette.bg(Color(0xFF4A7FD0)), minHeight: 8),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF64748B)))),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, bool value, IconData icon, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFFBBDEFB)).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border(Colors.white), width: 1), boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF90CAF9)).withOpacity(0.9), blurRadius: 15)]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppPalette.fg(Color(0xFF4A7FD0)), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF1E293B)))),
                Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.blueGrey).withOpacity(0.9))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CustomSwitch(value: value, onChanged: onChanged) // custom switch
        ],
      ),
    );
  }
}
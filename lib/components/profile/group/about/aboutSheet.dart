import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/profile/nameProfile/nameProfileSheet.dart';
import 'package:signlang/components/profile/skeleton/skeleton.dart';

import '../../../../l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class AboutSheet extends StatefulWidget{
  const AboutSheet({super.key});

  @override
  State<AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends State<AboutSheet> {
  final int _selectedIndex = -1;
  String _appVersion = '';
  bool _isLoading = true;
  bool _instagramLoading = false;
  bool _telegramLoading = false;
  bool _facebookLoading = false;

  late final aboutItem = AboutData(context: context).aboutItems;
// =======================================================================
  @override
  void initState(){ super.initState(); _initializeData(); _loadVersion(); }

// =======================================================================
  Future<void> _initializeData() async { await Future.wait([ AppLoading.ready(), ]); if (!mounted) return; setState(() { _isLoading = false; }); }

  Future<void> _handleInstagram() async {
    if (_instagramLoading) return;
    setState(() => _instagramLoading = true);
    try {
      // Simulate Google sign-in
      await Future.delayed(const Duration(seconds: 2));
      // await LinkStorage.saveGoogle(true, 'user@gmail.com');
    } finally { if (mounted) setState(() => _instagramLoading = false); }
  }

  Future<void> _handleTelegram() async {
    if (_telegramLoading) return;
    setState(() => _telegramLoading = true);
    try {
      // Simulate Google sign-in
      await Future.delayed(const Duration(seconds: 2));
      // await LinkStorage.saveGoogle(true, 'user@gmail.com');
    } finally { if (mounted) setState(() => _telegramLoading = false); }
  }

  Future<void> _handleFacebook() async {
    if (_facebookLoading) return;
    setState(() => _facebookLoading = true);
    try {
      // Simulate Google sign-in
      await Future.delayed(const Duration(seconds: 2));
      // await LinkStorage.saveGoogle(true, 'user@gmail.com');
    } finally { if (mounted) setState(() => _facebookLoading = false); }
  }

  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _loadVersion() async { final info = await PackageInfo.fromPlatform(); if (mounted) { setState(() => _appVersion = info.version); } }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    const ImageInstagram = 'web/icons/instagram.png'; const ImageTelegram = 'web/icons/telegram.png'; const ImageFacebook = 'web/icons/facebook.png';

    final Color isColors = _selectedIndex == -1 ? AppPalette.auto(Color(0xFFBBDEFB)).withOpacity(0.9) : AppPalette.auto(Color(0xFFBBDEFB)).withOpacity(0.5);
    final Color isColor =_selectedIndex == -1 ? AppPalette.auto(Color(0xFF4A7FD0)).withOpacity(0.5) : AppPalette.auto(Color(0xFF4A7FD0)).withOpacity(0.1);

    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: AboutSheetSkeleton.buildSkeleton()))
                else
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 0),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                              child: const Icon(Icons.arrow_back_outlined),
                            )
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.translate('about_the_application'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                              Text(loc.translate('about_the_application_sub'), style: TextStyle(fontSize: 18, color: AppPalette.fg(Colors.grey[700]!), fontWeight: FontWeight.w600))
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Column(
                            children: [
                              Image.asset('web/images/sign_lang_wrap.png', width: 120, height: 100, color: AppPalette.fg(Colors.blue[600]!)),
                              const SizedBox(height: 12),
                              Text('Uzbek Sign Language', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 25))
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: List.generate(aboutItem.length, (index) { return _buildAbout(aboutItem[index]); }))),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(child: Divider(thickness: 1, color: AppPalette.border(Colors.grey[400]!))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(loc.translate('social_networks'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[500]!)))),
                              Expanded(child: Divider(thickness: 1, color: AppPalette.border(Colors.grey[400]!))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppPalette.bg(Color(0xFFF1F5F9)).withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: isColor), boxShadow: [BoxShadow(color: isColors, blurRadius: 15)],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24), onTap: (_instagramLoading) ? null : _handleInstagram,
                                      child: Center(
                                        child: _instagramLoading ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.fg(Color(0xFF4A7FD0)))) : Image.asset(ImageInstagram, width: 36, height: 36),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppPalette.bg(Color(0xFFF1F5F9)).withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: isColor), boxShadow: [BoxShadow(color: isColors, blurRadius: 15)],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24), onTap: (_telegramLoading) ? null : _handleTelegram,
                                      child: Center(
                                        child: _telegramLoading
                                          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.fg(Color(0xFF4A7FD0)))) : Image.asset(ImageTelegram, width: 36, height: 36),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppPalette.bg(Color(0xFFF1F5F9)).withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: isColor), boxShadow: [BoxShadow(color: isColors, blurRadius: 15)],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24), onTap: (_facebookLoading) ? null : _handleFacebook,
                                      child: Center(
                                        child: _facebookLoading
                                          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.fg(Color(0xFF4A7FD0)))) : Image.asset(ImageFacebook, width: 36, height: 36),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(width: double.infinity, child: Align(alignment: Alignment.center, child: Text('App version $_appVersion', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppPalette.fg(Colors.grey))))),
                        const SizedBox(height: 18)
                      ],
                    ),
                  )
              ],
            )
          )
        ),
      ),
    );
  }

  Widget _buildAbout(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withOpacity(0.4), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF29B6F6)).withOpacity(0.9), blurRadius: 15)]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
                    child: Image.asset(item['image'], width: 22, height: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['titleKey'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(item['subKey'] ?? '', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13, color: AppPalette.fg(Colors.grey[700]!)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
              child: Center(child: Icon(Icons.keyboard_arrow_right_outlined, size: 24, color: AppPalette.fg(Color(0xFF0D47A1)).withOpacity(0.9))),
            )
          ],
        ),
      ),
    );
  }
}
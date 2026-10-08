import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../screens/profile.dart';
import '../../nameProfile/nameStore.dart';

import 'package:signlang/services/theme_service.dart';
class ChangeLink extends StatefulWidget {
  const ChangeLink({super.key});

  @override
  State<ChangeLink> createState() => _ChangeLinkState();
}

class _ChangeLinkState extends State<ChangeLink> with SingleTickerProviderStateMixin {
  bool isAppleConnected = false; bool isGoogleConnected = false;
  bool _isLoading = false; // false or true
  bool _showSuccess = false; // false or true
  String _connectedEmail = '';
  String _lastConnectedProvider = '';

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _loadLinkStatus();
  }

  Future<void> _loadLinkStatus() async {
    final status = await LinkStorage.load();
    if (mounted) {
      setState(() {
        isAppleConnected = status['apple']; isGoogleConnected = status['google'];
        // We don't set _showSuccess = true here so the user sees the list first.
        // But we can store the emails if we want to show them in success state later.
        if (isAppleConnected) _connectedEmail = status['apple_email'];
        else if (isGoogleConnected) _connectedEmail = status['google_email'];
      });
    }
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _handleConnect(String provider) async {
    setState(() { _isLoading = true; _lastConnectedProvider = provider; });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final email = provider == 'Apple' ? 'aziz234@icloud.com' : 'aziz234@gmail.com';
    
    if (provider == 'Apple') {
      await LinkStorage.saveApple(true, email);
      await LinkStorage.saveGoogle(false, null); // Switch off Google
    } else {
      await LinkStorage.saveGoogle(true, email);
      await LinkStorage.saveApple(false, null); // Switch off Apple
    }

    setState(() {
      _isLoading = false;
      _showSuccess = true;
      _connectedEmail = email;
      if (provider == 'Apple') {
        isAppleConnected = true;
        isGoogleConnected = false;
      } else {
        isGoogleConnected = true;
        isAppleConnected = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoading ? _buildLoadingState(loc) : _showSuccess ? _buildSuccessState(loc) : _buildInitialState(loc),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState(AppLocalizations loc) {
    const String ImageLink = 'web/icons/link.png';
    const String ImageApple = 'web/icons/apple.png';
    const String ImageGoogle = 'web/icons/google.png';

    return Column(
      key: const ValueKey('initial'),
      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFEEEEEE)).withOpacity(0.9), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppPalette.bg(Colors.black).withOpacity(0.05), border: Border.all(width: 1, color: AppPalette.border(Colors.white).withOpacity(0.9)), borderRadius: BorderRadius.circular(20)),
            child: Image.asset(ImageLink, width: 32, height: 32),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: Text(loc.translate('linked_accounts'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A))))),
        const SizedBox(height: 8),
        Center(
          child: Text(loc.translate('linked_accounts_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppPalette.fg(Color(0xFF0F172A)).withOpacity(0.7))),
        ),
        const SizedBox(height: 32),
        _buildLinkOption(icon: ImageApple, name: 'Apple', isConnected: isAppleConnected, onTap: isAppleConnected ? null : () => _handleConnect('Apple')),
        const SizedBox(height: 16),
        _buildLinkOption(icon: ImageGoogle, name: 'Google', isConnected: isGoogleConnected, onTap: isGoogleConnected ? null : () => _handleConnect('Google')),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
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
            child: Text(loc.translate('cancel'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLoadingState(AppLocalizations loc) {
    return Column(
      key: const ValueKey('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFEEEEEE)).withOpacity(0.9), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 40),
        CircularProgressIndicator(strokeWidth: 5, valueColor: AlwaysStoppedAnimation<Color>(AppPalette.fg(Color(0xFF4A7FD0)))),
        const SizedBox(height: 32),
        Text(loc.translate('connecting_title'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(loc.translate('linked_accounts_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppPalette.fg(Color(0xFF0F172A)).withOpacity(0.7))),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSuccessState(AppLocalizations loc) {
    const String ImagePass = 'web/images/pass.png';

    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFEEEEEE)).withOpacity(0.9), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Center(child: Image.asset(ImagePass, height: 96, width: 96)),
        const SizedBox(height: 24),
        Text(
          loc.translate('account_connected'), textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A))),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppPalette.fg(Color(0xFF0F172A)).withOpacity(0.7)),
              children: [
                TextSpan(text: loc.translate('account_connected_sub').split('%s')[0]),
                TextSpan(text: '($_connectedEmail)', style: TextStyle(color: AppPalette.fg(Color(0xFF4A7FD0)), fontWeight: FontWeight.w500)),
                if (loc.translate('account_connected_sub').contains('%s'))
                  TextSpan(text: loc.translate('account_connected_sub').split('%s')[1]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildLinkOption(
          icon: _lastConnectedProvider == 'Apple' ? 'web/icons/apple.png' : 'web/icons/google.png',
          name: _lastConnectedProvider,
          isConnected: true,
          onTap: null,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
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
            child: Text(loc.translate('cancel'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLinkOption({
    required String icon,
    required String name,
    required bool isConnected,
    required VoidCallback? onTap,
  }) {
    final loc = AppLocalizations.of(context)!;
    final isColors = isConnected ? AppPalette.auto(Color(0xFF2E7D32)) : AppPalette.auto(Color(0xFFC62828));
    final isColorIcon = isConnected ? AppPalette.auto(Color(0xFFC8E6C9)).withOpacity(0.8) : AppPalette.auto(Color(0xFFFFCDD2)).withOpacity(0.8);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), boxShadow: [BoxShadow(color: isColors, blurRadius: 15)]),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.8), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(14)),
              child: Image.asset(icon, width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.link)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: isColorIcon, borderRadius: BorderRadius.circular(10), border: Border.all(width: 1, color: AppPalette.border(Colors.white))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isConnected ? Icons.check_circle : Icons.cancel, size: 16, color: isColors),
                        const SizedBox(width: 4),
                        Text(loc.translate(isConnected ? 'connected' : 'disconnected'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isColors)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), shape: BoxShape.circle),
              child: Icon(Icons.keyboard_arrow_right, color: AppPalette.fg(Colors.grey[900]!)),
            )
          ],
        ),
      ),
    );
  }
}

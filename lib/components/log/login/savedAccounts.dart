import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signlang/components/log/langguageChoose.dart';
import 'package:signlang/components/log/login/emailAuth.dart';
import 'package:signlang/components/log/login/phoneLogin.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/saved_accounts.dart';
import 'package:signlang/services/theme_service.dart';

/// Accounts used on this phone, like Instagram's saved logins: shown after logging out
/// (and at start when nobody is logged in). Tap one to log in to it again.
class SavedAccountsScreen extends StatefulWidget {
  const SavedAccountsScreen({super.key});

  /// Where to go when nobody is logged in: this screen if some accounts are saved, else the language screen
  static Future<Widget> startScreen() async =>
      (await SavedAccounts.all()).isEmpty ? const LanguageChoose() : const SavedAccountsScreen();

  @override
  State<SavedAccountsScreen> createState() => _SavedAccountsScreenState();
}

class _SavedAccountsScreenState extends State<SavedAccountsScreen> {
  static const Color _blue = Color(0xFF4A7FD0);
  List<SavedAccount>? _accounts;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final accounts = await SavedAccounts.all();
    if (mounted) setState(() => _accounts = accounts);
  }

  // "+998901234567" -> "+998 90 123 45 67", as the phone screen shows it
  static String? _maskedPhone(String? phone) {
    final d = phone?.replaceAll(RegExp(r'\D'), '');
    if (d == null || d.length != 12) return phone;
    return '+998 ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, 10)} ${d.substring(10)}';
  }

  void _open(SavedAccount a) {
    HapticFeedback.selectionClick();
    final Widget screen = switch (a.method) {
      LoginMethod.password => EmailAuth(initialEmail: a.email),
      LoginMethod.phone => PhoneLogin(initialPhone: _maskedPhone(a.phone)),
      LoginMethod.google || LoginMethod.apple => PhoneLogin(autoSocial: a.method),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _remove(SavedAccount a) async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppPalette.border(Colors.white), width: 1)),
        title: Text(loc.translate('remove_saved_account'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 19)),
        content: Text(loc.translate('remove_saved_account_sub'), style: TextStyle(fontSize: 15, color: AppPalette.fg(Colors.grey[700]!))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.translate('remove'), style: TextStyle(color: AppPalette.fg(Colors.red[700]!)))),
        ],
      ),
    );
    if (ok != true) return;
    await SavedAccounts.remove(a.id);
    if (!mounted) return;
    final left = await SavedAccounts.all();
    if (!mounted) return;
    // the last one removed: back to the usual start
    if (left.isEmpty) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LanguageChoose()), (route) => false);
    } else {
      setState(() => _accounts = left);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accounts = _accounts;
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(const Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: accounts == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                  children: [
                    Center(child: Image.asset('web/images/uzbek_sign_language.png', height: 120)),
                    const SizedBox(height: 20),
                    Text(loc.translate('saved_accounts'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(loc.translate('saved_accounts_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppPalette.fg(Colors.grey[600]!))),
                    const SizedBox(height: 24),
                    for (final a in accounts) _accountCard(a),
                    const SizedBox(height: 8),
                    // ===== another account =====
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailAuth(startWithRegister: false))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.bg(_blue).withValues(alpha: 0.15), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                          shadowColor: AppPalette.shadow(const Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                          side: BorderSide(width: 1, color: AppPalette.border(const Color(0xFF1A237E)).withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(loc.translate('login_other_account'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.blue[900]!))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailAuth())),
                        child: Text(loc.translate('create_new_account'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppPalette.fg(Colors.blue))),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _accountCard(SavedAccount a) {
    final loc = AppLocalizations.of(context)!;
    final (IconData icon, String how) = switch (a.method) {
      LoginMethod.password => (Icons.alternate_email_rounded, ''),
      LoginMethod.phone => (Icons.phone_iphone_rounded, ''),
      LoginMethod.google => (Icons.g_mobiledata_rounded, loc.translate('via_google')),
      LoginMethod.apple => (Icons.apple, loc.translate('via_apple')),
    };
    final String sub = [if (a.method == LoginMethod.phone) _maskedPhone(a.subtitle) ?? '' else a.subtitle, how].where((s) => s.isNotEmpty).join(' · ');
    final String initial = a.title.isEmpty ? '?' : a.title.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _open(a),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
              boxShadow: [BoxShadow(color: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
            ),
            child: Row(children: [
              // photo, or the first letter of the name
              Container(
                width: 52, height: 52, clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE3F2FD)), shape: BoxShape.circle, border: Border.all(width: 1, color: AppPalette.border(Colors.white))),
                child: a.avatar != null
                    ? Image.network(a.avatar!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _initial(initial))
                    : _initial(initial),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(icon, size: 15, color: AppPalette.fg(Colors.grey[600]!)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: AppPalette.fg(Colors.grey[700]!)))),
                    ]),
                  ],
                ]),
              ),
              IconButton(
                onPressed: () => _remove(a),
                tooltip: loc.translate('remove'),
                icon: Icon(Icons.close_rounded, size: 20, color: AppPalette.fg(Colors.grey[600]!)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _initial(String letter) => Center(
    child: Text(letter, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppPalette.fg(Colors.blue[800]!))),
  );
}

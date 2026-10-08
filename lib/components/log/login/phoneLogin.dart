import 'package:flutter/material.dart';
import 'package:signlang/services/push_service.dart';
import 'package:signlang/services/firebase_setup.dart';
import 'package:signlang/services/account_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/log/login/codeNumber.dart';
import 'package:signlang/components/log/login/emailAuth.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/main.dart';

import '../../profile/nameProfile/nameStore.dart';

import 'package:signlang/services/theme_service.dart';
class PhoneLogin extends StatefulWidget{
  const PhoneLogin({super.key});

  @override
  State<PhoneLogin> createState() => _PhoneLoginState();
}

class _PhoneLoginState extends State<PhoneLogin> {
  final int _selectedIndex = -1;
  bool _googleLoading = false;
  bool _appleLoading = false;
  bool _sending = false;
  late String _initialPhone = '';
  final TextEditingController numberController = TextEditingController(text: '');
  bool get isValid => numberController.text.replaceAll(RegExp(r'[^0-9]'), '').length >= 9;

  final maskFormatter = MaskTextInputFormatter(
    mask: '## ### ## ##',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState(){ super.initState(); _initializeData(); }

  // ====================================================================
  Future<void> _initializeData() async {
    await _loadUserData();
    numberController.addListener(_onChanged);
  }

  void _onChanged() {if (mounted) {setState(() {});}}

  @override
  void dispose() {
    numberController.removeListener(_onChanged);
    numberController.dispose();
    super.dispose();
  }

  bool get isChanged { return numberController.text.trim() != _initialPhone.trim(); }

  Future<void> _loadUserData() async {
    String? savedNumber = await NumberStorage.load();

    if (!mounted) return;

    if (savedNumber != null && savedNumber.startsWith('+998 ')) {
      savedNumber = savedNumber.replaceFirst('+998 ', '');
    }

    setState(() {
      numberController.text = savedNumber ?? '';
      _initialPhone = numberController.text;
    });
  }

  // Future<void> _saveData() async {
  //   await NumberStorage.save(numberController.text);
  //
  //   final success = await ApiService.updateProfile( // api
  //       phone: numberController.text
  //   );
  //
  //   if (success && mounted) {
  //     setState(() {
  //       _initialNumber = numberController.text;
  //     });
  //   }
  // }


// ======================== button ========================
  Future<void> _handleValidation() async {
    if (_sending) return;
    final digits = numberController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('please_number')),
          backgroundColor: AppPalette.bg(Color(0xFFD32F2F)), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final fullPhone = '+998 ${numberController.text}';

    // Ask the server to send the SMS code
    setState(() => _sending = true);
    try {
      final debugCode = await UzslApi.requestCode('+998$digits');
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => CodeNumber(phoneNumber: fullPhone, debugCode: debugCode)));
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e, onRetry: _handleValidation);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _handleRegister() {
    FocusScope.of(context).unfocus();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailAuth()));
    }
  }

  Future<void> _handleGoogle() => _socialLogin(apple: false);

  Future<void> _handleApple() => _socialLogin(apple: true);

  /// Sign in with Google or Apple through Firebase, then log into the UzSL server (like email login).
  Future<void> _socialLogin({required bool apple}) async {
    if (_googleLoading || _appleLoading) return;
    final loc = AppLocalizations.of(context)!;
    if (!FirebaseSetup.ready) { showRedSnackBar(context, loc.translate('email_login_off')); return; }
    setState(() => apple ? _appleLoading = true : _googleLoading = true);
    try {
      final AuthProvider provider = apple ? (OAuthProvider('apple.com')..addScope('email')..addScope('name')) : (GoogleAuthProvider()..addScope('email'));
      final credential = await FirebaseAuth.instance.signInWithProvider(provider);
      final user = credential.user!;

      await UzslApi.firebaseLogin((await user.getIdToken())!, fullName: user.displayName);
      if (mounted) await AccountService.afterLogin(context);
      final email = user.email ?? '';
      apple ? await LinkStorage.saveApple(true, email) : await LinkStorage.saveGoogle(true, email);
      if (email.isNotEmpty) await EmailStorage.save(email);

      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainWrapper(initialTab: 0)), (route) => false);
      PushService.afterLogin();
    } on FirebaseAuthException catch (e) {
      // Closing the Google/Apple window is not an error
      if (const {'canceled', 'web-context-canceled', 'popup-closed-by-user', 'user-cancelled'}.contains(e.code)) return;
      debugPrint('${apple ? 'Apple' : 'Google'} sign-in failed: ${e.code} ${e.message}');
      if (mounted) {
        showRedSnackBar(context, switch (e.code) {
          'operation-not-allowed' => loc.translate('social_login_off').replaceAll('{name}', apple ? 'Apple' : 'Google'),
          'network-request-failed' => loc.translate('no_internet'),
          'account-exists-with-different-credential' => loc.translate('verify_email_first'),
          _ => e.message ?? e.code,
        });
      }
    } on ApiException catch (e) {
      await FirebaseSetup.signOut();
      if (mounted) e.status == 409 ? showRedSnackBar(context, loc.translate('verify_email_first')) : showApiError(context, e);
    } finally { if (mounted) setState(() => apple ? _appleLoading = false : _googleLoading = false); }
  }

// ======================================================

  @override
  Widget build(BuildContext context) {
    const String ImagePathPhone = 'web/icons/phone.png'; const String ImagePathGoogle = 'web/icons/google.png';
    const String ImagePathApple = 'web/icons/apple.png';
    final AppLocalizations loc = AppLocalizations.of(context)!;
    final Color isColors = _selectedIndex == -1 ? AppPalette.auto(Color(0xFFBBDEFB)).withValues(alpha: 0.9) : AppPalette.auto(Color(0xFFBBDEFB)).withValues(alpha: 0.5);
    final Color isColor =_selectedIndex == -1 ? AppPalette.auto(Color(0xFF4A7FD0)).withValues(alpha: 0.5) : AppPalette.auto(Color(0xFF4A7FD0)).withValues(alpha: 0.1);

    return Scaffold(
      body: SizedBox(
        width: double.infinity, height: double.infinity,
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== 1) back button and icon/text =====
                            if (Navigator.canPop(context)) ...[
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                                  child: const Icon(Icons.arrow_back_outlined),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else
                              const SizedBox(height: 40),
                            Image.asset(ImagePathPhone, width: 36, height: 36),
                            const SizedBox(height: 8), Text(loc.translate('phone_number'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                            const SizedBox(height: 4), Text(loc.translate('phone_number_sub'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[600]!))),
                            const SizedBox(height: 18), Text(loc.translate('phone_number'), style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.2), blurRadius: 15)]),
                              child: TextField(
                                controller: numberController, keyboardType: TextInputType.phone, inputFormatters: [maskFormatter], onChanged: (_) => setState(() {}),
                                style: TextStyle(color: AppPalette.fg(Color(0xFF0F172A)), fontSize: 15, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  border: InputBorder.none, hintText: 'XX XXX XX XX', hintStyle: TextStyle(color: AppPalette.fg(Color(0xFF94A3B8)), fontSize: 15, fontWeight: FontWeight.w400),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('+998', style: TextStyle(color: AppPalette.fg(Color(0xFF0F172A)), fontSize: 15, fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 12), Container(width: 1.5, height: 28, color: AppPalette.bg(Color(0xFFCBD5E1)))
                                        ]
                                      )
                                    )
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0)
                                )
                              )
                            ),
                            const SizedBox(height: 22),
                            // ===== 2) button =====
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: _handleValidation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !isValid ? AppPalette.bg(Color(0xFF4A7FD0)).withOpacity(0.1) : AppPalette.bg(Color(0xFF4A7FD0)).withOpacity(0.15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), foregroundColor: AppPalette.fg(Colors.white),
                                  elevation: !isValid ? 0 : 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withOpacity(0.9), side: BorderSide(width: 1, color: !isValid ? AppPalette.border(Colors.black12) : AppPalette.border(Color(0xFF1A237E)).withOpacity(0.2))
                                ),
                                child: _sending
                                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.fg(Colors.blue[900]!)))
                                  : Text(loc.translate('continue'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: !isValid ? AppPalette.fg(Colors.blue[700]!) : AppPalette.fg(Colors.blue[900]!))),
                              ),
                            ),
                            const SizedBox(height: 26),
                            // ===== 3) divider line =====
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppPalette.border(Colors.grey), thickness: 1, height: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(loc.translate('or'), style: TextStyle(color: AppPalette.fg(Color(0xFF94A3B8)), fontWeight: FontWeight.w400, fontSize: 16, letterSpacing: 0.5)),
                                ),
                                Expanded(child: Divider(color: AppPalette.border(Colors.grey), thickness: 1, height: 1)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // ===== 4) google and apple =====
                            Row(
                              children: [
                                // --- 1) google button ---
                                Expanded(
                                  child: Container(
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppPalette.bg(Color(0xFFF1F5F9)).withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: isColor), boxShadow: [BoxShadow(color: isColors, blurRadius: 15)],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(24), onTap: (_googleLoading || _appleLoading) ? null : _handleGoogle,
                                        child: Center(
                                          child: _googleLoading
                                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.fg(Color(0xFF4A7FD0))))
                                            : Image.asset(ImagePathGoogle, width: 36, height: 36),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // --- 2) apple button ---
                                Expanded(
                                  child: Container(
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppPalette.bg(Color(0xFFF1F5F9)).withOpacity(0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: isColor), boxShadow: [BoxShadow(color: isColors, blurRadius: 15)],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(24), onTap: (_googleLoading || _appleLoading) ? null : _handleApple,
                                        child: Center(
                                          child: _appleLoading
                                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.fg(Color(0xFF4A7FD0))))
                                            : Image.asset(ImagePathApple, width: 36, height: 36),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity, height: 50,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(loc.translate('account'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: _handleRegister, behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12), // bigger tap area than the text itself
                                      child: Text(loc.translate('account_sub'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppPalette.fg(Colors.blue))),
                                    ),
                                  ),
                                ],
                              )
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            )
          ),
        ),
      ),
    );
  }
}
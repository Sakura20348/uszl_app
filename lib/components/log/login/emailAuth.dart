import 'package:firebase_auth/firebase_auth.dart';
import 'package:signlang/services/account_service.dart';
import 'package:flutter/material.dart';
import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/components/log/login/phoneLogin.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/push_service.dart';
import 'package:signlang/services/firebase_setup.dart';

import '../../profile/nameProfile/nameStore.dart';

import 'package:signlang/services/theme_service.dart';

/// Email + password sign-up / log-in, opened from "Register" on the phone login screen.
class EmailAuth extends StatefulWidget {
  final bool startWithRegister;
  const EmailAuth({super.key, this.startWithRegister = true});

  @override
  State<EmailAuth> createState() => _EmailAuthState();
}

class _EmailAuthState extends State<EmailAuth> with SingleTickerProviderStateMixin {
  static const Color _blue = Color(0xFF4A7FD0);
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static const Duration _switchDuration = Duration(milliseconds: 280);

  late bool _isRegister = widget.startWithRegister;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _submitted = false; // show field errors only after the first tap on the button
  bool _loading = false;

  // "Confirm password" folds away / out; its content stays visible while it animates
  late final AnimationController _confirmAnim = AnimationController(vsync: this, duration: _switchDuration, value: widget.startWithRegister ? 1 : 0);
  late final Animation<double> _confirmSize = CurvedAnimation(parent: _confirmAnim, curve: Curves.easeInOutCubic);
  late final Animation<double> _confirmFade = CurvedAnimation(parent: _confirmAnim, curve: const Interval(0.3, 1, curve: Curves.easeOut));

  @override
  void dispose() {
    _confirmAnim.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _emailError(AppLocalizations loc) => _emailPattern.hasMatch(_emailController.text.trim()) ? null : loc.translate('invalid_email');
  String? _passwordError(AppLocalizations loc) => _passwordController.text.length >= 8 ? null : loc.translate('password_short');
  String? _confirmError(AppLocalizations loc) => !_isRegister || _confirmController.text == _passwordController.text ? null : loc.translate('password_mismatch');

  bool _isValid(AppLocalizations loc) => _emailError(loc) == null && _passwordError(loc) == null && _confirmError(loc) == null;

// ======================== button ========================
  Future<void> _handleValidation() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _submitted = true);
    if (!_isValid(loc) || _loading) return;

    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!FirebaseSetup.ready) {
      await EmailStorage.save(email);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneLogin()));
      }
      return;
    }
    setState(() => _loading = true);
    try {
      // 1) Firebase Authentication: create the account or sign in
      final auth = FirebaseAuth.instance;
      UserCredential credential;
      var created = false;
      if (_isRegister) {
        try {
          credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
          created = true;
        } on FirebaseAuthException catch (e) {
          if (e.code != 'email-already-in-use') rethrow;
          // Already registered (e.g. an earlier try stopped half way): log in with the same password.
          // A wrong password still fails, with "wrong email or password".
          credential = await auth.signInWithEmailAndPassword(email: email, password: password);
        }
      } else {
        credential = await auth.signInWithEmailAndPassword(email: email, password: password);
      }
      final user = credential.user!;
      if (created) {
        // Lets the user prove the email is theirs (needed to join an account that already uses it)
        await user.sendEmailVerification();
        if (mounted) showSnackBar(context, loc.translate('verification_sent'));
      }

      // 2) This app's server: trade the Firebase ID token for its own login
      await UzslApi.firebaseLogin((await user.getIdToken())!);
      // The phone's progress becomes this account's (another person's is removed), then its progress is loaded
      if (mounted) await AccountService.afterLogin(context);
      await EmailStorage.save(email);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneLogin()));
      PushService.afterLogin();
    } on FirebaseAuthException catch (e) {
      if (mounted) showRedSnackBar(context, _firebaseError(loc, e));
    } on ApiException catch (e) {
      if (mounted) {
        if (e.status == 409) {
          showRedSnackBar(context, loc.translate('verify_email_first'));
        } else {
          showApiError(context, e, onRetry: _handleValidation);
        }
      }
      // The server didn't log in: don't stay half signed in
      await FirebaseAuth.instance.signOut();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _firebaseError(AppLocalizations loc, FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return loc.translate('email_in_use');
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found': return loc.translate('wrong_email_password');
      case 'invalid-email': return loc.translate('invalid_email');
      case 'weak-password': return loc.translate('weak_password');
      case 'too-many-requests': return loc.translate('too_many_tries');
      case 'network-request-failed': return loc.translate('no_internet');
      case 'operation-not-allowed': return loc.translate('email_login_off');
      default: return e.message ?? e.code;
    }
  }

  void _switchMode(bool register) {
    if (register == _isRegister) return;
    setState(() { _isRegister = register; _submitted = false; });
    if (register) {
      _confirmAnim.forward();
    } else {
      _confirmAnim.reverse().whenComplete(() { if (mounted && !_isRegister) _confirmController.clear(); });
    }
  }

// ======================================================
  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    final bool valid = _isValid(loc);

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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== 1) back =====
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.arrow_back_outlined),
                              ),
                            ),
                            const SizedBox(height: 28),
                            // ===== 2) icon and text =====
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppPalette.bg(_blue).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.mail_rounded, size: 28, color: AppPalette.fg(_blue)),
                            ),
                            const SizedBox(height: 10),
                            AnimatedSize(
                              duration: _switchDuration, curve: Curves.easeInOutCubic, alignment: Alignment.topLeft,
                              child: AnimatedSwitcher(
                                duration: _switchDuration, switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic,
                                // keep old and new text left-aligned while they cross (the default centers them → jump)
                                layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(animation), child: child),
                                ),
                                child: Column(
                                  key: ValueKey(_isRegister), crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(loc.translate(_isRegister ? 'email_title_register' : 'log_in'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                                    const SizedBox(height: 4),
                                    Text(loc.translate(_isRegister ? 'email_sub_register' : 'email_sub_login'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[600]!))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // ===== 3) register / log in switch =====
                            _modeSwitch(loc),
                            const SizedBox(height: 20),
                            // ===== 4) fields =====
                            _label(loc.translate('email')),
                            _field(
                              controller: _emailController, hint: 'name@example.com', icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress, autofill: const [AutofillHints.email],
                              error: _submitted ? _emailError(loc) : null,
                            ),
                            const SizedBox(height: 14),
                            _label(loc.translate('password')),
                            _field(
                              controller: _passwordController, hint: loc.translate('password_hint'), icon: Icons.lock_outline_rounded,
                              obscure: _hidePassword, onToggleObscure: () => setState(() => _hidePassword = !_hidePassword),
                              autofill: [_isRegister ? AutofillHints.newPassword : AutofillHints.password],
                              error: _submitted ? _passwordError(loc) : null,
                            ),
                            // folds like a SizeTransition but without clipping, so the field keeps its full shadow
                            AnimatedBuilder(
                              animation: _confirmSize,
                              builder: (context, child) => Align(alignment: Alignment.topCenter, heightFactor: _confirmSize.value, child: child),
                              child: FadeTransition(
                                opacity: _confirmFade,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 14),
                                    _label(loc.translate('confirm_password')),
                                    _field(
                                      controller: _confirmController, hint: loc.translate('confirm_password'), icon: Icons.lock_reset_rounded,
                                      obscure: _hideConfirm, onToggleObscure: () => setState(() => _hideConfirm = !_hideConfirm),
                                      autofill: const [AutofillHints.newPassword], enabled: _isRegister,
                                      error: _submitted ? _confirmError(loc) : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // ===== 5) button =====
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: _handleValidation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !valid ? AppPalette.bg(_blue).withValues(alpha: 0.1) : AppPalette.bg(_blue).withValues(alpha: 0.15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), foregroundColor: AppPalette.fg(Colors.white),
                                  elevation: !valid ? 0 : 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                                  side: BorderSide(width: 1, color: !valid ? AppPalette.border(Colors.black12) : AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                                ),
                                child: _loading
                                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.fg(_blue)))
                                  : AnimatedSwitcher(
                                      duration: _switchDuration,
                                      child: Text(loc.translate(_isRegister ? 'account_sub' : 'log_in'), key: ValueKey(_isRegister), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: !valid ? AppPalette.fg(Colors.blue[700]!) : AppPalette.fg(Colors.blue[900]!))),
                                    ),
                              ),
                            ),
                            const Spacer(),
                            // ===== 6) back to phone =====
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneLogin()));
                                },
                                icon: Icon(Icons.phone_iphone_rounded, size: 18, color: AppPalette.fg(Colors.blue)),
                                label: Text(loc.translate('use_phone'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppPalette.fg(Colors.blue))),
                              ),
                            ),
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

  // same behavior as the Saved page tabs: the highlight jumps straight to the tapped tab
  Widget _modeSwitch(AppLocalizations loc) {
    final tabs = [(label: loc.translate('account_sub'), register: true), (label: loc.translate('log_in'), register: false)];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE2E8F0)).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => _switchMode(tab.register),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _isRegister == tab.register ? AppPalette.bg(Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(16),
                    boxShadow: _isRegister == tab.register ? [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))] : null,
                  ),
                  child: Text(
                    tab.label, textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15, fontWeight: _isRegister == tab.register ? FontWeight.w700 : FontWeight.w500,
                      color: _isRegister == tab.register ? AppPalette.fg(Colors.blue[900]!) : AppPalette.fg(Colors.grey[600]!),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15)),
  );

  Widget _field({
    required TextEditingController controller, required String hint, required IconData icon,
    TextInputType? keyboardType, bool obscure = false, VoidCallback? onToggleObscure, List<String>? autofill, String? error, bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppPalette.bg(Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: error != null ? AppPalette.border(Color(0xFFD32F2F)) : Colors.transparent),
            boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.2), blurRadius: 15)],
          ),
          child: TextField(
            controller: controller, keyboardType: keyboardType, obscureText: obscure, autofillHints: autofill, enabled: enabled,
            autocorrect: false, enableSuggestions: !obscure, onChanged: (_) => setState(() {}),
            textAlignVertical: TextAlignVertical.center, // hint and text in the middle, level with the icons
            style: TextStyle(color: AppPalette.fg(Color(0xFF0F172A)), fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14), hintText: hint, hintStyle: TextStyle(color: AppPalette.fg(Color(0xFF94A3B8)), fontSize: 15, fontWeight: FontWeight.w400),
              prefixIcon: Icon(icon, size: 20, color: AppPalette.fg(Color(0xFF64748B))),
              suffixIcon: onToggleObscure == null ? null : IconButton(
                onPressed: onToggleObscure,
                icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: AppPalette.fg(Color(0xFF64748B))),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(error, style: TextStyle(fontSize: 12, color: AppPalette.fg(Color(0xFFD32F2F)))),
          ),
      ],
    );
  }
}

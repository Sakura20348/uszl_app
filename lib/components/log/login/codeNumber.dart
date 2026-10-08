import 'dart:async';
import 'package:signlang/services/account_service.dart';
import 'package:signlang/services/saved_accounts.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signlang/api/api_errors.dart';
import 'package:signlang/api/uzsl_api.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/push_service.dart';

import '../../profile/nameProfile/nameStore.dart';

import 'package:signlang/services/theme_service.dart';
import 'package:signlang/services/onboarding_answers.dart';
import 'package:signlang/components/log/createProfile.dart';
class CodeNumber extends StatefulWidget{
  final String phoneNumber;
  /// The code itself, while the server has no SMS provider (shown in debug builds only)
  final String? debugCode;
  const CodeNumber({super.key, required this.phoneNumber, this.debugCode});

  @override
  State<CodeNumber> createState() => _CodeNumberState();
}

class _CodeNumberState extends State<CodeNumber> {
  Timer? _timer;
  int _secondsLeft = 60;
  String _code = '';
  bool _verifying = false;
  bool get _isComplete => _code.length == 6;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTestCode(widget.debugCode));
  }

  // No SMS provider yet: the server sends the code back (only in its test mode, never with real SMS),
  // so it's shown here in every build, debug or release
  void _showTestCode(String? code) {
    if (code == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.translate('test_code').replaceAll('{code}', code)),
        behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) { timer.cancel(); if (mounted) setState(() {}); } else { if (mounted) setState(() => _secondsLeft--); }
    });
  }

  String get _formattedTime {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handleResend() async {
    try {
      final code = await UzslApi.requestCode(widget.phoneNumber);
      _startTimer();
      _showTestCode(code);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e, onRetry: _handleResend);
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

// ======================== button ========================
  Future<void> _handleValidation() async {
    if (_verifying) return;
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('please_code')), backgroundColor: AppPalette.bg(Color(0xFFD32F2F)), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
      return;
    }

    // Check the code with the server; it logs in (or creates the account)
    setState(() => _verifying = true);
    try {
      await UzslApi.verifyCode(widget.phoneNumber, _code);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _verifying = false);
        showApiError(context, e, onRetry: _handleValidation);
      }
      return;
    }

    // The phone's progress becomes this account's (another person's is removed), then its progress is loaded
    if (mounted) await AccountService.afterLogin(context, method: LoginMethod.phone);

    // Save the verified phone number
    await NumberStorage.save(widget.phoneNumber);
    // Onboarding answers given before login go to the server (dashboard: Source, daily goal, ...)
    await OnboardingAnswers.sync();

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProfile()));
    }
    // Ask to allow notifications (unless answered in onboarding) and register this phone
    PushService.afterLogin();
  }

  @override
  Widget build(BuildContext context) {
    const String ImagePathCode = 'web/icons/code.png';
    final AppLocalizations loc = AppLocalizations.of(context)!;
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== 1) back =====
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.arrow_back_outlined),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // ===== 2) text otp =====
                            Image.asset(ImagePathCode, width: 36, height: 36),
                            const SizedBox(height: 8),
                            Text(loc.translate('confirmation_code'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                            const SizedBox(height: 4),
                            Text(loc.translate('confirmation_code_sub'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[600]!))),
                            const SizedBox(height: 18),
                            Text(widget.phoneNumber, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(height: 8),
                            // =====  OTP boxes =====
                            _OtpInput(
                              length: 6,
                              onChanged: (code) => setState(() => _code = code),
                              onCompleted: (code) {
                                setState(() => _code = code);
                                print('Entered code: $code');
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: _secondsLeft == 0 ? _handleResend : null,
                                  child: Text(
                                    loc.translate('resend_code'),
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _secondsLeft == 0 ? AppPalette.fg(Color(0xFF4A7FD0)) : AppPalette.fg(Color(0xFF94A3B8))),
                                  ),
                                ),
                                Text(_formattedTime, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppPalette.fg(Colors.grey[600]!)),
                                ),
                              ],
                            ),
                            const Spacer(),

                            // ===== 3) button =====
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: _handleValidation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_isComplete ? AppPalette.bg(Color(0xFF4A7FD0)).withOpacity(0.1) : AppPalette.bg(Color(0xFF4A7FD0)).withOpacity(0.15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), foregroundColor: AppPalette.fg(Colors.white),
                                  elevation: !_isComplete ? 0 : 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withOpacity(0.9),
                                  side: BorderSide(width: 1, color: !_isComplete ? AppPalette.border(Colors.black12) : AppPalette.border(Color(0xFF1A237E)).withOpacity(0.2))
                                ),
                                child: _verifying
                                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.fg(Colors.blue[900]!)))
                                  : Text(loc.translate('continue'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: !_isComplete ? AppPalette.fg(Colors.blue[700]!) : AppPalette.fg(Colors.blue[900]!))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  const _OtpInput({
    required this.length,
    required this.onCompleted,
    this.onChanged,
    });

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

/// One hidden text field holds the whole code; the boxes only show its digits.
/// So backspace always removes the last digit, typing fills the next box, and a pasted or
/// SMS-autofilled code fills every box at once.
class _OtpInputState extends State<_OtpInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {})); // highlight the active box only while typing
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String code) {
    setState(() {});
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      _focusNode.unfocus();
      widget.onCompleted(code);
    }
  }

  // tapping any box edits the code from its end, the cursor never sits in the middle
  void _focusInput() {
    _focusNode.requestFocus();
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final String code = _controller.text;
    final int activeIndex = code.length.clamp(0, widget.length - 1);

    return Stack(
      children: [
        // ===== the real (invisible) input =====
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller, focusNode: _focusNode,
              keyboardType: TextInputType.number, maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofillHints: const [AutofillHints.oneTimeCode],
              showCursor: false, enableInteractiveSelection: false, autocorrect: false, enableSuggestions: false,
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
              onChanged: _onChanged,
            ),
          ),
        ),
        // ===== the boxes =====
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focusInput,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final bool filled = index < code.length;
              final bool active = _focusNode.hasFocus && index == activeIndex;
              return Container(
                width: 54, height: 48, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppPalette.bg(Color(0xFFEEF2FF)), borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: active ? AppPalette.border(Color(0xFF4A7FD0)) : AppPalette.border(Colors.grey), width: active ? 1 : 0.5),
                ),
                child: Text(
                  filled ? code[index] : '0',
                  style: filled
                    ? TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))
                    : TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: AppPalette.fg(Color(0xFFB0B8C4))),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signlang/components/uiTranslation/group/textToGesture.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/theme_service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech → Text: live transcript of what the user says, until they tap stop.
/// The transcript can be copied, shared, or shown in signs (Text → Gesture).
class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> with SingleTickerProviderStateMixin {
  static const Color _blue = Color(0xFF4A7FD0);
  static const Color _liveRed = Color(0xFFAE3A12);
  static const List<({String id, String label})> _languages = [
    (id: 'uz_UZ', label: "O'zbek"), (id: 'ru_RU', label: 'Русский'), (id: 'en_US', label: 'English'),
  ];

  final SpeechToText _speech = SpeechToText();
  bool _ready = false;        // engine initialized
  bool _unavailable = false;  // no recognizer / mic permission refused
  bool _wantListening = false; // user pressed start and not stop yet
  bool _listening = false;
  Set<String> _installed = {};
  late String _language;

  String _finalText = '';
  String _partial = '';
  double _level = 0; // smoothed sound level 0..1
  final Stopwatch _elapsed = Stopwatch();
  Timer? _ticker;
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  double _fontSize = 22;
  int _weight = 1;
  static const List<FontWeight> _weights = [FontWeight.w300, FontWeight.w500, FontWeight.w700];

  String get _text => [_finalText, _partial].where((s) => s.isNotEmpty).join(' ');

  @override
  void initState() {
    super.initState();
    _language = 'en_US';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready && !_unavailable) {
      final code = Localizations.localeOf(context).languageCode;
      _language = switch (code) { 'uz' => 'uz_UZ', 'ru' => 'ru_RU', _ => 'en_US' };
      _init();
    }
  }

  @override
  void dispose() {
    _wantListening = false;
    _ticker?.cancel();
    _speech.cancel();
    _pulse.dispose();
    super.dispose();
  }

// ======================== speech ========================
  Future<void> _init() async {
    final ok = await _speech.initialize(onStatus: _onStatus, onError: _onError);
    if (!mounted) return;
    if (!ok) { setState(() => _unavailable = true); return; }
    final locales = await _speech.locales();
    if (!mounted) return;
    setState(() { _ready = true; _installed = locales.map((l) => l.localeId).toSet(); });
  }

  void _onStatus(String status) {
    if (!mounted) return;
    final stopped = status == 'done' || status == 'notListening';
    if (stopped) {
      setState(() { _listening = false; _commitPartial(); });
      // Android ends a session after a short pause: keep going until the user taps stop
      if (_wantListening) Future.delayed(const Duration(milliseconds: 250), () { if (mounted && _wantListening && !_speech.isListening) _listen(); });
    } else if (status == 'listening') {
      setState(() => _listening = true);
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted) return;
    if (error.errorMsg.contains('permission') || error.errorMsg.contains('insufficient')) {
      _stop();
      setState(() => _unavailable = true);
    }
    // no_match / speech_timeout are normal pauses; _onStatus restarts listening
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      if (result.finalResult) {
        _finalText = [_finalText, result.recognizedWords].where((s) => s.isNotEmpty).join(' ');
        _partial = '';
      } else {
        _partial = result.recognizedWords;
      }
    });
  }

  void _commitPartial() {
    if (_partial.isEmpty) return;
    _finalText = [_finalText, _partial].where((s) => s.isNotEmpty).join(' ');
    _partial = '';
  }

  Future<void> _listen() async {
    await _speech.listen(
      onResult: _onResult,
      onSoundLevelChange: (level) {
        // Android reports roughly -2..10 dB; map to 0..1 and smooth
        final v = ((level + 2) / 12).clamp(0.0, 1.0);
        if (mounted) setState(() => _level = _level * 0.6 + v * 0.4);
      },
      listenOptions: SpeechListenOptions(
        localeId: _installed.contains(_language) ? _language : null,
        listenMode: ListenMode.dictation, partialResults: true, autoPunctuation: true, cancelOnError: false,
        listenFor: const Duration(minutes: 1), pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _start() async {
    if (!_ready) { await _init(); if (!_ready) return; }
    setState(() { _wantListening = true; _unavailable = false; });
    _elapsed.start();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
    _pulse.repeat();
    await _listen();
  }

  Future<void> _stop() async {
    _wantListening = false;
    _elapsed.stop();
    _ticker?.cancel(); _ticker = null;
    _pulse.stop();
    await _speech.stop();
    if (mounted) setState(() { _listening = false; _level = 0; _commitPartial(); });
  }

  void _toggle() => _wantListening ? _stop() : _start();

  void _clear() {
    setState(() { _finalText = ''; _partial = ''; _elapsed.reset(); });
  }

  Future<void> _changeLanguage(String id) async {
    if (id == _language) return;
    final wasListening = _wantListening;
    if (wasListening) await _stop();
    setState(() => _language = id);
    if (wasListening) _start();
  }

  void _copy() {
    if (_text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('gt_copied')), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)));
  }

  void _share() {
    if (_text.isEmpty) return;
    SharePlus.instance.share(ShareParams(text: _text));
  }

  Future<void> _showInSigns() async {
    if (_text.isEmpty) return;
    if (_wantListening) await _stop();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => TextToGesture(initialText: _text)));
  }

  String get _clock {
    final s = _elapsed.elapsed.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

// ======================================================
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = AppColors.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ===== 1) header =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.arrow_back_outlined)),
                    ),
                    Expanded(child: Text(loc.translate('speech_text'), textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text))),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== 2) language =====
                      Text(loc.translate('sp_language'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 8),
                      _languageChips(),
                      if (_ready && !_installed.contains(_language)) ...[
                        const SizedBox(height: 6),
                        Text(loc.translate('sp_lang_missing'), style: TextStyle(fontSize: 12, color: AppPalette.fg(const Color(0xFFB45309)))),
                      ],
                      const SizedBox(height: 12),
                      // ===== 3) microphone =====
                      _micCard(loc),
                      const SizedBox(height: 12),
                      // ===== 4) transcript =====
                      _transcriptCard(loc, c),
                      const SizedBox(height: 12),
                      // ===== 5) font =====
                      _fontCard(loc, c),
                      const SizedBox(height: 12),
                      // ===== 6) tip =====
                      _tipCard(loc, c),
                      const SizedBox(height: 16),
                      // ===== 7) show in signs =====
                      SizedBox(
                        width: double.infinity, height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _text.isEmpty ? null : _showInSigns,
                          icon: const Icon(Icons.sign_language_rounded),
                          label: Text(loc.translate('tg_show'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.bg(_blue), foregroundColor: Colors.white, disabledBackgroundColor: AppPalette.bg(_blue).withValues(alpha: 0.45), disabledForegroundColor: Colors.white,
                            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageChips() {
    return Row(
      children: [
        for (final lang in _languages) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => _changeLanguage(lang.id),
              child: Container(
                height: 40, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _language == lang.id ? AppPalette.bg(_blue) : AppPalette.bg(Colors.white).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12), border: Border.all(color: AppPalette.border(Colors.white)),
                ),
                child: Text(lang.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _language == lang.id ? Colors.white : AppPalette.fg(const Color(0xFF475569)))),
              ),
            ),
          ),
          if (lang != _languages.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _micCard(AppLocalizations loc) {
    final bool on = _wantListening;
    final String status = _unavailable ? 'sp_unavailable' : (on ? 'sp_listening' : 'sp_tap_to_speak');
    return Container(
      width: double.infinity, height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppPalette.bg(const Color(0xFF5B8FE0)), AppPalette.bg(const Color(0xFF3D6DBA))]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppPalette.shadow(_blue).withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          if (on)
            Positioned(
              top: 14, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFBBF7D0), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('LIVE · $_clock', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 170, height: 150,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => CustomPaint(painter: _RingsPainter(phase: _pulse.value, level: on && _listening ? _level : 0, active: on), child: child),
                    child: Center(
                      child: GestureDetector(
                        onTap: _toggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 84, height: 84,
                          decoration: BoxDecoration(
                            color: on ? AppPalette.bg(_liveRed) : Colors.white, shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Icon(on ? Icons.stop_rounded : Icons.mic_rounded, size: 40, color: on ? Colors.white : AppPalette.fg(_blue)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(loc.translate(status), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(AppColors c) => BoxDecoration(
    color: c.isDark ? c.card : Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20),
    border: Border.all(color: c.cardBorder), boxShadow: [BoxShadow(color: AppPalette.shadow(_blue).withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
  );

  Widget _label(String text) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.fg(_blue)));

  Widget _iconAction(IconData icon, VoidCallback onTap, bool enabled) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Padding(padding: const EdgeInsets.all(5), child: Icon(icon, size: 19, color: AppPalette.fg(enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)))),
  );

  Widget _transcriptCard(AppLocalizations loc, AppColors c) {
    final bool empty = _text.isEmpty;
    final TextStyle base = TextStyle(fontSize: _fontSize, fontWeight: _weights[_weight], height: 1.35, color: c.text);
    return Container(
      width: double.infinity, constraints: const BoxConstraints(minHeight: 130), padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
      decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(loc.translate('sp_text'))),
              _iconAction(Icons.copy_rounded, _copy, !empty),
              _iconAction(Icons.ios_share_rounded, _share, !empty),
              _iconAction(Icons.delete_outline_rounded, _clear, !empty && !_wantListening),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: empty
              ? Text(loc.translate('sp_text_hint'), style: base.copyWith(fontSize: 17, fontWeight: FontWeight.w500, color: AppPalette.fg(const Color(0xFFB6C0CC))))
              // words still being recognized are lighter
              : Text.rich(TextSpan(style: base, children: [
                  TextSpan(text: _finalText),
                  if (_partial.isNotEmpty) TextSpan(text: '${_finalText.isEmpty ? '' : ' '}$_partial', style: TextStyle(color: c.subText.withValues(alpha: 0.7))),
                ])),
          ),
        ],
      ),
    );
  }

  Widget _fontCard(AppLocalizations loc, AppColors c) {
    final weightLabels = [loc.translate('gt_light'), loc.translate('gt_medium'), loc.translate('gt_bold')];
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.translate('gt_font_size')),
          Row(
            children: [
              Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.subText)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 2, activeTrackColor: AppPalette.fg(const Color(0xFFCBD5E1)), inactiveTrackColor: AppPalette.fg(const Color(0xFFCBD5E1)), thumbColor: Colors.white, overlayColor: AppPalette.fg(_blue).withValues(alpha: 0.1), thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 3)),
                  child: Slider(value: _fontSize, min: 14, max: 34, onChanged: (v) => setState(() => _fontSize = v)),
                ),
              ),
              Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.subText)),
            ],
          ),
          const SizedBox(height: 4),
          Text(loc.translate('gt_font_weight'), style: TextStyle(fontSize: 13, color: c.subText)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE2E8F0)).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _weight = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _weight == i ? AppPalette.bg(Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(11),
                          boxShadow: _weight == i ? [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : null,
                        ),
                        child: Text(weightLabels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: _weight == i ? FontWeight.w700 : FontWeight.w400, color: _weight == i ? c.text : c.subText)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(AppLocalizations loc, AppColors c) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(c),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFFFEDD5)), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.info_rounded, size: 20, color: AppPalette.fg(const Color(0xFFF59E0B))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.translate('gt_tip_title'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                const SizedBox(height: 4),
                Text(loc.translate('sp_tip'), style: TextStyle(fontSize: 13, height: 1.4, color: c.subText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft rings around the mic: they ripple out while listening and grow with the voice level.
class _RingsPainter extends CustomPainter {
  final double phase;
  final double level;
  final bool active;
  _RingsPainter({required this.phase, required this.level, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const double base = 42; // mic button radius
    if (!active) {
      canvas.drawCircle(center, base + 14, Paint()..color = Colors.white.withValues(alpha: 0.12));
      return;
    }
    // inner ring follows the voice
    canvas.drawCircle(center, base + 8 + 22 * level, Paint()..color = Colors.white.withValues(alpha: 0.18));
    // outer ripples
    for (int i = 0; i < 2; i++) {
      final t = (phase + i * 0.5) % 1.0;
      final radius = base + 10 + t * (math.min(size.width, size.height) / 2 - base - 6);
      canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withValues(alpha: 0.45 * (1 - t)));
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.phase != phase || old.level != level || old.active != active;
}

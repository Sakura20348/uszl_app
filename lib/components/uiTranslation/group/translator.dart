import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/sign_lookup.dart';
import 'package:signlang/services/sign_recognizer.dart';
import 'package:signlang/services/theme_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:signlang/components/uiTextBooks/nameTextbooks/nameTextbooks.dart';
import 'package:signlang/components/uiTranslation/engine/signSequencePlayer.dart';
import 'package:signlang/main.dart';

/// What the user gives (input) or gets (output).
enum TransMode { voice, text, sign }

/// One translator between voice, text and sign language.
/// Input and output are picked with the two dropdowns (or the swap button / the mode pill).
class Translator extends StatefulWidget {
  final TransMode initialInput;
  final TransMode initialOutput;
  /// False while hidden (e.g. inside a tab that isn't shown): camera, mic, video and speech are stopped then.
  final bool isActive;
  const Translator({super.key, this.initialInput = TransMode.voice, this.initialOutput = TransMode.sign, this.isActive = true});

  @override
  State<Translator> createState() => _TranslatorState();
}

class _TranslatorState extends State<Translator> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const Color _blue = Color(0xFF4A7FD0);
  static const Color _green = Color(0xFF16A34A);
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25];
  static const List<int> _durations = [3, 5, 8, 10];
  static const List<({String code, String speech, String tts})> _languages = [
    (code: 'UZ', speech: 'uz_UZ', tts: 'uz-UZ'), (code: 'RU', speech: 'ru_RU', tts: 'ru-RU'), (code: 'EN', speech: 'en_US', tts: 'en-US'),
  ];

  late TransMode _input = widget.initialInput;
  late TransMode _output = widget.initialOutput == widget.initialInput ? TransMode.sign : widget.initialOutput;
  bool _unlocked = LessonProgress.instance.completedCount > 0;

  // ===== source text (from voice, typing or the camera) =====
  final TextEditingController _textInput = TextEditingController();
  String _sourceText = '';   // what is being translated / was translated
  String _partial = '';      // voice: words still being recognized
  bool _delivered = false;   // a result is on screen

  // ===== voice input =====
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  Set<String> _speechLocales = {};
  bool _listening = false;
  double _level = 0;
  late String _lang;
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  // ===== sign input (camera) =====
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _camera;
  bool _cameraDenied = false;
  bool _recording = false;
  bool _recognizing = false;
  int _seconds = 3;
  int _left = 0;
  Timer? _countdown;

  // ===== outputs =====
  final SignSequencePlayer _player = SignSequencePlayer();
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  int _ttsStart = 0, _ttsEnd = 0;
  double _ttsProgress = 0;

  // ===== text settings =====
  double _fontSize = 20;
  int _weight = 1;
  static const List<FontWeight> _weights = [FontWeight.w300, FontWeight.w500, FontWeight.w700];

  bool get _busy => _listening || _recording || _recognizing || _player.playing || _speaking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player.addListener(_onPlayer);
    _textInput.addListener(() => setState(() {}));
    if (_input == TransMode.sign) WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
    _tts.setProgressHandler((text, start, end, word) { if (mounted) setState(() { _ttsStart = start; _ttsEnd = end; _ttsProgress = text.isEmpty ? 0 : end / text.length; }); });
    _tts.setCompletionHandler(() { if (mounted) setState(() { _speaking = false; _ttsProgress = 1; _ttsStart = _ttsEnd = 0; }); _syncWave(); });
    _tts.setCancelHandler(() { if (mounted) setState(() => _speaking = false); _syncWave(); });
    _tts.setErrorHandler((_) { if (mounted) setState(() => _speaking = false); _syncWave(); });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode.toUpperCase();
    _lang = _languages.any((l) => l.code == code) ? code : 'UZ';
  }

  @override
  void didUpdateWidget(Translator old) {
    super.didUpdateWidget(old);
    if (old.isActive && !widget.isActive) {
      _stopAll();
      _releaseCamera();
    } else if (!old.isActive && widget.isActive) {
      setState(() => _unlocked = LessonProgress.instance.completedCount > 0);
      if (_input == TransMode.sign) _initCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopAll();
      _releaseCamera();
    } else if (state == AppLifecycleState.resumed && widget.isActive && _input == TransMode.sign && _camera == null) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdown?.cancel();
    _speech.cancel();
    _tts.stop();
    _camera?.dispose();
    _player.removeListener(_onPlayer);
    _player.dispose();
    _wave.dispose();
    _textInput.dispose();
    super.dispose();
  }

  void _onPlayer() { if (mounted) setState(() {}); }

  void _syncWave() {
    if (_listening || _speaking) { if (!_wave.isAnimating) _wave.repeat(reverse: true); } else { _wave.stop(); }
  }

  ({String code, String speech, String tts}) get _language => _languages.firstWhere((l) => l.code == _lang);

// ======================== modes ========================
  void _setModes(TransMode input, TransMode output) {
    if (input == output) return;
    final bool inputChanged = input != _input;
    _stopAll();
    // the text we had keeps going when the input becomes "text"
    if (input == TransMode.text && _sourceText.isNotEmpty && _textInput.text.isEmpty) _textInput.text = _sourceText;
    setState(() { _input = input; _output = output; _delivered = false; _partial = ''; });
    _player.clear();
    if (inputChanged) {
      if (input == TransMode.sign) { _initCamera(); } else { _releaseCamera(); }
    }
  }

  void _pickInput(TransMode m) => _setModes(m, m == _output ? _input : _output);
  void _pickOutput(TransMode m) => _setModes(m == _input ? _output : _input, m);
  void _swap() => _setModes(_output, _input);

// ======================== main actions ========================
  void _onMainButton() {
    if (_busy) { _stopAll(); return; }
    switch (_input) {
      case TransMode.voice: _startListening();
      case TransMode.text: _deliver(_textInput.text);
      case TransMode.sign: _startRecording();
    }
  }

  void _stopAll() {
    if (_listening) { _speech.stop(); _listening = false; _commitPartial(); }
    if (_recording) { _countdown?.cancel(); _recording = false; try { _camera?.stopVideoRecording(); } catch (_) {} }
    _player.stop();
    if (_speaking) { _tts.stop(); _speaking = false; }
    _level = 0;
    _syncWave();
    if (mounted) setState(() {});
  }

  void _reset() {
    _stopAll();
    _player.clear();
    _textInput.clear();
    setState(() { _sourceText = ''; _partial = ''; _delivered = false; _ttsProgress = 0; _ttsStart = _ttsEnd = 0; });
  }

  /// Send the source text to the chosen output.
  Future<void> _deliver(String text) async {
    text = text.trim();
    if (text.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { _sourceText = text; _delivered = true; });
    switch (_output) {
      case TransMode.sign:
        _player.load(SignLookup.translate(text));
      case TransMode.voice:
        _player.load(SignLookup.translate(text)); // the same text in Uzbek sign language, alongside the voice
        await _speak(text);
      case TransMode.text:
        break; // the text card shows it
    }
  }

// ======================== voice input ========================
  Future<void> _startListening() async {
    if (!_speechReady) {
      _speechReady = await _speech.initialize(onStatus: _onSpeechStatus, onError: (_) {});
      if (!_speechReady) { _snack('sp_unavailable'); return; }
      _speechLocales = (await _speech.locales()).map((l) => l.localeId).toSet();
    }
    _player.clear();
    setState(() { _listening = true; _sourceText = ''; _partial = ''; _delivered = false; });
    _syncWave();
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: _speechLocales.contains(_language.speech) ? _language.speech : null,
        listenMode: ListenMode.dictation, partialResults: true, autoPunctuation: true, pauseFor: const Duration(seconds: 3),
      ),
      onSoundLevelChange: (level) { if (mounted) setState(() => _level = _level * 0.6 + ((level + 2) / 12).clamp(0.0, 1.0) * 0.4); },
      onResult: (r) {
        if (!mounted) return;
        if (r.finalResult) {
          setState(() { _partial = ''; _listening = false; _level = 0; });
          _syncWave();
          _deliver(r.recognizedWords);
        } else {
          setState(() => _partial = r.recognizedWords);
        }
      },
    );
  }

  void _onSpeechStatus(String status) {
    if (!mounted || !(status == 'done' || status == 'notListening') || !_listening) return;
    setState(() { _listening = false; _level = 0; });
    _commitPartial();
    _syncWave();
  }

  // stopped before the recognizer finished: translate what we have
  void _commitPartial() {
    if (_partial.isEmpty) return;
    final text = _partial;
    _partial = '';
    _deliver(text);
  }

// ======================== sign input (camera) ========================
  Future<void> _initCamera() async {
    if (!widget.isActive || _camera != null) return;
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        final front = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        _cameraIndex = front >= 0 ? front : 0;
      }
      if (_cameras.isEmpty) return;
      final controller = CameraController(_cameras[_cameraIndex], ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted || _input != TransMode.sign || !widget.isActive) { controller.dispose(); return; }
      setState(() { _camera = controller; _cameraDenied = false; });
    } on CameraException catch (e) {
      if (mounted) setState(() => _cameraDenied = e.code.contains('AccessDenied') || e.code.contains('Permission'));
    }
  }

  void _releaseCamera() {
    final camera = _camera;
    _camera = null;
    camera?.dispose();
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _recording) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _releaseCamera();
    await _initCamera();
  }

  Future<void> _startRecording() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) { _initCamera(); return; }
    _player.clear();
    setState(() { _recording = true; _left = _seconds; _sourceText = ''; _delivered = false; });
    try { await camera.startVideoRecording(); } on CameraException { /* recognition can still run without a clip */ }
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _left--);
      if (_left <= 0) _finishRecording();
    });
  }

  Future<void> _finishRecording() async {
    _countdown?.cancel();
    final loc = AppLocalizations.of(context)!;
    setState(() { _recording = false; _recognizing = true; });
    XFile? clip;
    try { if (_camera?.value.isRecordingVideo ?? false) clip = await _camera!.stopVideoRecording(); } on CameraException { clip = null; }
    final text = await SignRecognizer.recognize(clip: clip, debugDemoText: loc.translate('gt_demo_result'));
    if (!mounted) return;
    setState(() => _recognizing = false);
    if (text == null || text.isEmpty) { _snack('gt_not_recognized'); return; }
    _deliver(text);
  }

// ======================== voice output ========================
  Future<void> _speak(String text) async {
    try { if (await _tts.isLanguageAvailable(_language.tts) == true) await _tts.setLanguage(_language.tts); } catch (_) {}
    await _tts.setSpeechRate(0.5 * _player.speed);
    setState(() { _speaking = true; _ttsProgress = 0; _ttsStart = _ttsEnd = 0; });
    _syncWave();
    await _tts.speak(text);
  }

  void _toggleSpeak() {
    if (_speaking) { _tts.stop(); _player.stop(); setState(() => _speaking = false); _syncWave(); }
    else if (_sourceText.isNotEmpty) { _player.replay(); _speak(_sourceText); }
  }

// ======================== helpers ========================
  void _snack(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate(key)), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

  void _copy() {
    if (_sourceText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _sourceText));
    _snack('gt_copied');
  }

  String _modeLabel(AppLocalizations loc, TransMode m) => loc.translate(switch (m) { TransMode.voice => 'tr_voice', TransMode.text => 'tr_text', TransMode.sign => 'tr_sign' });

  static IconData _modeIcon(TransMode m) => switch (m) { TransMode.voice => Icons.mic_rounded, TransMode.text => Icons.text_fields_rounded, TransMode.sign => Icons.front_hand_rounded };

  static String _speedLabel(double s) => '${s == s.roundToDouble() ? s.toInt() : s}x';

  /// Source text with the word being signed / spoken in bold.
  InlineSpan _highlighted(String text, TextStyle base, Color strong) {
    int start = -1, end = -1;
    if (_output == TransMode.voice && _speaking && _ttsEnd > _ttsStart && _ttsEnd <= text.length) {
      start = _ttsStart; end = _ttsEnd;
    } else if (_output == TransMode.sign && _player.currentWord >= 0) {
      final words = text.split(RegExp(r'\s+')).where((t) => SignLookup.normalize(t).isNotEmpty).toList();
      int t = 0;
      for (int w = 0; w < _player.words.length && t < words.length; w++) {
        final n = math.min(_player.words[w].tokens, words.length - t);
        if (w == _player.currentWord) {
          final before = words.sublist(0, t).join(' ');
          start = before.isEmpty ? 0 : before.length + 1;
          end = start + words.sublist(t, t + n).join(' ').length;
          break;
        }
        t += n;
      }
      final joined = words.join(' ');
      if (start >= 0) return TextSpan(style: base, children: [
        TextSpan(text: joined.substring(0, start)),
        TextSpan(text: joined.substring(start, end), style: TextStyle(fontWeight: FontWeight.w800, color: strong)),
        TextSpan(text: joined.substring(end)),
      ]);
    }
    if (start < 0) return TextSpan(text: text, style: base);
    return TextSpan(style: base, children: [
      TextSpan(text: text.substring(0, start)),
      TextSpan(text: text.substring(start, end), style: TextStyle(fontWeight: FontWeight.w800, color: strong)),
      TextSpan(text: text.substring(end)),
    ]);
  }

// ======================== settings sheet (gear) ========================
  Future<void> _openSettings() async {
    double size = _fontSize, speed = _player.speed; int weight = _weight, seconds = _seconds;
    final loc = AppLocalizations.of(context)!;
    final bool? apply = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final c = AppColors.of(sheetContext);
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + MediaQuery.of(sheetContext).viewPadding.bottom * 0.5),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(26)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: c.track, borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 14),
                _label(loc.translate('gt_font_size')),
                Row(
                  children: [
                    Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.subText)),
                    Expanded(child: _slider(size, (v) => setSheet(() => size = v))),
                    Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.subText)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(loc.translate('gt_font_weight'), style: TextStyle(fontSize: 13, color: c.subText)),
                const SizedBox(height: 8),
                _segmented([loc.translate('gt_light'), loc.translate('gt_medium'), loc.translate('gt_bold')], weight, (i) => setSheet(() => weight = i), c),
                const SizedBox(height: 14),
                _settingRow(loc.translate('tg_speed'), DropdownButton<double>(
                  value: speed, isDense: true, borderRadius: BorderRadius.circular(12), underline: const SizedBox(),
                  items: [for (final s in _speeds) DropdownMenuItem(value: s, child: Text(_speedLabel(s), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)))],
                  onChanged: (v) { if (v != null) setSheet(() => speed = v); },
                ), c),
                if (_input == TransMode.sign) ...[
                  const SizedBox(height: 10),
                  _settingRow(loc.translate('gt_duration'), DropdownButton<int>(
                    value: seconds, isDense: true, borderRadius: BorderRadius.circular(12), underline: const SizedBox(),
                    items: [for (final s in _durations) DropdownMenuItem(value: s, child: Text('${s}s', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)))],
                    onChanged: (v) { if (v != null) setSheet(() => seconds = v); },
                  ), c),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppPalette.bg(_blue), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(loc.translate('tg_confirm'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: TextButton(onPressed: () => Navigator.pop(sheetContext, false), child: Text(loc.translate('cancel'), style: TextStyle(fontSize: 15, color: c.text))),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (apply == true && mounted) {
      setState(() { _fontSize = size; _weight = weight; _seconds = seconds; });
      if (speed != _player.speed) _player.setSpeed(speed);
    }
  }

  Widget _settingRow(String label, Widget control, AppColors c) => Row(
    children: [
      Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: c.subText))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE2E8F0)).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
        child: control,
      ),
    ],
  );

  Widget _slider(double value, ValueChanged<double> onChanged) => SliderTheme(
    data: SliderTheme.of(context).copyWith(trackHeight: 2, activeTrackColor: AppPalette.fg(const Color(0xFFCBD5E1)), inactiveTrackColor: AppPalette.fg(const Color(0xFFCBD5E1)), thumbColor: Colors.white, overlayColor: AppPalette.fg(_blue).withValues(alpha: 0.1), thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 3)),
    child: Slider(value: value, min: 14, max: 34, onChanged: onChanged),
  );

  Widget _segmented(List<String> labels, int selected, ValueChanged<int> onTap, AppColors c) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE2E8F0)).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
    child: Row(
      children: [
        for (int i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected == i ? AppPalette.bg(Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(11),
                  boxShadow: selected == i ? [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Text(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: selected == i ? FontWeight.w700 : FontWeight.w400, color: selected == i ? c.text : c.subText)),
              ),
            ),
          ),
      ],
    ),
  );

// ======================================================
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final double navBar = MediaQuery.of(context).padding.bottom; // bottom navigation (extendBody) + system bar

    return Scaffold(
      backgroundColor: c.surface,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
        child: SafeArea(
          bottom: false,
          child: !_unlocked
            ? _lockedView(loc, c, navBar)
            : Column(
                children: [
                  // ===== 1) input / swap / output =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        if (Navigator.canPop(context)) ...[
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(width: 46, height: 46, decoration: _pillDecoration(c), child: const Icon(Icons.arrow_back_outlined)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(child: _modeDropdown(loc, _input, _pickInput, c)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _swap,
                          child: Container(width: 46, height: 46, decoration: _pillDecoration(c), child: Icon(Icons.sync_alt_rounded, size: 20, color: AppPalette.fg(const Color(0xFF64748B)))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _modeDropdown(loc, _output, _pickOutput, c)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ===== 2) mode pill =====
                  _modePill(loc),
                  const SizedBox(height: 12),
                  // ===== 3) input + output =====
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _inputCard(loc, c),
                          const SizedBox(height: 12),
                          _outputCard(loc, c),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  // ===== 4) actions =====
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, navBar + 10),
                    child: Row(
                      children: [
                        _squareButton(Icons.settings_rounded, _openSettings, c),
                        const SizedBox(width: 10),
                        Expanded(child: _mainButton(loc)),
                        const SizedBox(width: 10),
                        _squareButton(Icons.refresh_rounded, _reset, c),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _lockedView(AppLocalizations loc, AppColors c, double navBar) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, navBar + 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(color: AppPalette.bg(_blue), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppPalette.shadow(_blue).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))]),
              child: const Icon(Icons.menu_book_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(loc.translate('trans_locked_title'), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 8),
            Text(loc.translate('trans_locked_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.45, color: c.subText)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainWrapper(initialTab: 0)), (route) => false),
                style: ElevatedButton.styleFrom(backgroundColor: AppPalette.bg(_blue), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                child: Text(loc.translate('go_to_lessons'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _pillDecoration(AppColors c) => BoxDecoration(
    color: c.isDark ? c.card : Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(15), border: Border.all(color: c.cardBorder),
  );

  Widget _modeDropdown(AppLocalizations loc, TransMode value, ValueChanged<TransMode> onPick, AppColors c) {
    return PopupMenuButton<TransMode>(
      onSelected: onPick,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        for (final m in TransMode.values)
          PopupMenuItem(
            value: m,
            child: Row(children: [Icon(_modeIcon(m), size: 18, color: AppPalette.fg(_blue)), const SizedBox(width: 10), Text(_modeLabel(loc, m), style: TextStyle(fontWeight: m == value ? FontWeight.w700 : FontWeight.w500))]),
          ),
      ],
      child: Container(
        height: 46, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: _pillDecoration(c),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_modeIcon(value), size: 18, color: AppPalette.fg(_blue)),
            const SizedBox(width: 6),
            Flexible(child: Text(_modeLabel(loc, value), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text))),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: c.subText),
          ],
        ),
      ),
    );
  }

  /// "Ovoz → Imo-ishora ▾": all translation directions in one list.
  Widget _modePill(AppLocalizations loc) {
    final pairs = [for (final i in TransMode.values) for (final o in TransMode.values) if (i != o) (i, o)];
    return PopupMenuButton<(TransMode, TransMode)>(
      onSelected: (p) => _setModes(p.$1, p.$2),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        for (final p in pairs)
          PopupMenuItem(value: p, child: Text('${_modeLabel(loc, p.$1)} → ${_modeLabel(loc, p.$2)}', style: TextStyle(fontWeight: p.$1 == _input && p.$2 == _output ? FontWeight.w700 : FontWeight.w500))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFD6E4FA)), borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_modeLabel(loc, _input)} → ${_modeLabel(loc, _output)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.fg(_blue))),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppPalette.fg(_blue)),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(AppColors c) => BoxDecoration(
    color: c.isDark ? c.card : Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(22),
    border: Border.all(color: c.cardBorder), boxShadow: [BoxShadow(color: AppPalette.shadow(_blue).withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
  );

  Widget _label(String text) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.fg(_blue)));

  Widget _smallChip(String text, {VoidCallback? onTap, IconData? icon, bool arrow = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE2E8F0)).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: AppPalette.fg(const Color(0xFF475569))), const SizedBox(width: 3)],
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.fg(const Color(0xFF475569)))),
          if (arrow) Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppPalette.fg(const Color(0xFF475569))),
        ],
      ),
    ),
  );

  Widget _languageChip() => PopupMenuButton<String>(
    onSelected: (code) => setState(() => _lang = code),
    position: PopupMenuPosition.under,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    itemBuilder: (_) => [for (final l in _languages) PopupMenuItem(value: l.code, child: Text(l.code, style: TextStyle(fontWeight: l.code == _lang ? FontWeight.w800 : FontWeight.w500)))],
    child: _smallChip(_lang, arrow: true),
  );

// ======================== input card ========================
  Widget _inputCard(AppLocalizations loc, AppColors c) {
    final String title = switch (_input) { TransMode.voice => 'tr_in_voice', TransMode.text => 'tg_input', TransMode.sign => 'tr_in_sign' };
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(loc.translate(title))),
              if (_input == TransMode.sign) ...[
                if (_recording) _smallChip('LIVE · ${_left}s', icon: Icons.fiber_manual_record_rounded),
                const SizedBox(width: 6),
                GestureDetector(onTap: _switchCamera, child: Icon(Icons.cameraswitch_rounded, size: 20, color: AppPalette.fg(const Color(0xFF64748B)))),
              ] else
                _languageChip(),
            ],
          ),
          const SizedBox(height: 10),
          switch (_input) {
            TransMode.voice => _voiceInput(loc, c),
            TransMode.text => _textInputField(loc, c),
            TransMode.sign => _cameraInput(loc),
          },
        ],
      ),
    );
  }

  Widget _voiceInput(AppLocalizations loc, AppColors c) {
    final String transcript = [_sourceText, _partial].where((s) => s.isNotEmpty).join(' ');
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _listening ? _stopAll : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: c.isDark ? c.chip : Colors.white, shape: BoxShape.circle,
                border: Border.all(color: _listening ? AppPalette.border(_blue).withValues(alpha: 0.25) : Colors.white, width: 8 + 10 * _level),
                boxShadow: [BoxShadow(color: AppPalette.shadow(_blue).withValues(alpha: _listening ? 0.25 : 0.08), blurRadius: 18)],
              ),
              child: Icon(Icons.mic_rounded, size: 40, color: _listening ? AppPalette.fg(_blue) : AppPalette.fg(const Color(0xFF8A94A3))),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_listening || transcript.isNotEmpty) ...[
          SizedBox(height: 26, child: AnimatedBuilder(animation: _wave, builder: (_, _) => CustomPaint(size: const Size(double.infinity, 26), painter: _WavePainter(filled: _listening ? 0.3 + 0.7 * _level : 1, phase: _wave.value, moving: _listening, color: AppPalette.fg(_blue))))),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: transcript.isEmpty
              ? Text(loc.translate('tg_listening'), style: TextStyle(fontSize: 15, color: c.subText))
              : Text.rich(TextSpan(children: [
                  _highlighted(_sourceText, TextStyle(fontSize: _fontSize, fontWeight: _weights[_weight], color: c.subText), c.text),
                  if (_partial.isNotEmpty) TextSpan(text: '${_sourceText.isEmpty ? '' : ' '}$_partial', style: TextStyle(fontSize: _fontSize, color: c.subText.withValues(alpha: 0.6))),
                ])),
          ),
        ] else
          Text(loc.translate('tr_voice_hint').replaceAll('{button}', loc.translate('tr_show')), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.4, color: c.subText)),
      ],
    );
  }

  Widget _textInputField(AppLocalizations loc, AppColors c) {
    final TextStyle style = TextStyle(fontSize: _fontSize, fontWeight: _weights[_weight], height: 1.3, color: c.text);
    if (_delivered && _sourceText.isNotEmpty && (_player.playing || _speaking)) {
      // while it is being signed / spoken: the current word in bold
      return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text.rich(_highlighted(_sourceText, style.copyWith(color: c.subText), c.text)));
    }
    return TextField(
      controller: _textInput, minLines: 3, maxLines: 6, maxLength: 200,
      textInputAction: TextInputAction.done, onSubmitted: (v) => _deliver(v),
      style: style,
      decoration: InputDecoration(
        border: InputBorder.none, isDense: true, counterStyle: TextStyle(fontSize: 11, color: c.subText),
        hintText: loc.translate('tg_input_hint'), hintStyle: style.copyWith(color: AppPalette.fg(const Color(0xFFB6C0CC)), fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _cameraInput(AppLocalizations loc) {
    final camera = _camera;
    final bool ready = camera != null && camera.value.isInitialized;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 240, width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF4A5A66)),
            if (ready)
              FittedBox(fit: BoxFit.cover, child: SizedBox(width: camera.value.previewSize?.height ?? 1, height: camera.value.previewSize?.width ?? 1, child: CameraPreview(camera)))
            else
              Center(
                child: _cameraDenied
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 40),
                          const SizedBox(height: 8),
                          Text(loc.translate('gt_camera_denied'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _initCamera,
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            child: Text(loc.translate('gt_allow_camera')),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
              ),
            IgnorePointer(child: CustomPaint(painter: _DashedCirclePainter(color: Colors.white.withValues(alpha: 0.85)))),
            if (_recognizing)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 8),
                      Text(loc.translate('gt_processing'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

// ======================== output card ========================
  Widget _outputCard(AppLocalizations loc, AppColors c) {
    final String title = switch (_output) { TransMode.sign => 'tr_out_sign', TransMode.text => 'tr_out_text', TransMode.voice => 'tr_out_voice' };
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(loc.translate(title))),
              if (_output != TransMode.text)
                PopupMenuButton<double>(
                  onSelected: _player.setSpeed,
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [for (final s in _speeds) PopupMenuItem(value: s, child: Text(_speedLabel(s), style: TextStyle(fontWeight: s == _player.speed ? FontWeight.w800 : FontWeight.w500)))],
                  child: _smallChip(_speedLabel(_player.speed), arrow: true),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: switch (_output) { TransMode.sign => _player.replay, TransMode.voice => _toggleSpeak, TransMode.text => _copy },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE2E8F0)).withValues(alpha: 0.8), shape: BoxShape.circle),
                  child: Icon(_output == TransMode.text ? Icons.copy_rounded : Icons.replay_rounded, size: 15, color: AppPalette.fg(const Color(0xFF475569))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          switch (_output) {
            TransMode.sign => SizedBox(
                height: 260,
                child: SignPlayerView(
                  player: _player,
                  emptyIcon: Icons.touch_app_rounded,
                  emptyText: loc.translate(_input == TransMode.voice ? 'tr_hint_voice_sign' : 'tr_hint_sign'),
                  noSignText: loc.translate('tg_no_sign'),
                ),
              ),
            TransMode.text => _textOutput(loc, c),
            TransMode.voice => _voiceOutput(loc, c),
          },
        ],
      ),
    );
  }

  Widget _textOutput(AppLocalizations loc, AppColors c) {
    if (_sourceText.isEmpty || !_delivered) return _emptyOutput(Icons.notes_rounded, loc.translate('tr_hint_text'), c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(_sourceText, style: TextStyle(fontSize: _fontSize + 2, fontWeight: _weights[_weight], height: 1.35, color: c.text)),
        const SizedBox(height: 10),
        Row(
          children: [
            _smallChip(loc.translate('tr_copy'), icon: Icons.copy_rounded, onTap: _copy),
            const SizedBox(width: 8),
            _smallChip(loc.translate('tr_share'), icon: Icons.ios_share_rounded, onTap: () => SharePlus.instance.share(ShareParams(text: _sourceText))),
          ],
        ),
      ],
    );
  }

  Widget _voiceOutput(AppLocalizations loc, AppColors c) {
    if (_sourceText.isEmpty || !_delivered) return _emptyOutput(Icons.graphic_eq_rounded, loc.translate('tr_hint_voice'), c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_player.isEmpty) ...[
          SizedBox(height: 220, child: SignPlayerView(player: _player, emptyText: '', noSignText: loc.translate('tg_no_sign'))),
          const SizedBox(height: 10),
        ],
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: c.isDark ? c.chip : Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleSpeak,
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppPalette.bg(_blue), borderRadius: BorderRadius.circular(12)), child: Icon(_speaking ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(child: SizedBox(height: 30, child: AnimatedBuilder(animation: _wave, builder: (_, _) => CustomPaint(painter: _WavePainter(filled: _ttsProgress, phase: _wave.value, moving: _speaking, color: AppPalette.fg(_blue)))))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(_highlighted(_sourceText, TextStyle(fontSize: 15, color: c.subText), c.text)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: _ttsProgress.clamp(0.0, 1.0), minHeight: 8, backgroundColor: AppPalette.bg(const Color(0xFFDCFCE7)), valueColor: AlwaysStoppedAnimation(AppPalette.fg(_green))))),
            const SizedBox(width: 10),
            Text('${(_ttsProgress * 100).clamp(0, 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppPalette.fg(_green))),
          ],
        ),
      ],
    );
  }

  Widget _emptyOutput(IconData icon, String text, AppColors c) => SizedBox(
    height: 150, width: double.infinity,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 44, color: AppPalette.fg(_blue).withValues(alpha: 0.6)),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.4, color: c.subText)),
      ],
    ),
  );

  Widget _squareButton(IconData icon, VoidCallback onTap, AppColors c) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: c.isDark ? c.card : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Icon(icon, color: AppPalette.fg(const Color(0xFF475569))),
    ),
  );

  Widget _mainButton(AppLocalizations loc) {
    final bool busy = _busy;
    final bool canStart = _input != TransMode.text || _textInput.text.trim().isNotEmpty;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: busy || canStart ? _onMainButton : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: busy ? AppPalette.bg(const Color(0xFFD6E4FA)) : AppPalette.bg(_blue),
          foregroundColor: busy ? AppPalette.fg(_blue) : Colors.white,
          disabledBackgroundColor: AppPalette.bg(_blue).withValues(alpha: 0.45), disabledForegroundColor: Colors.white,
          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(loc.translate(busy ? 'tr_stop' : 'tr_show'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Dashed circle that shows where to keep the face / hands.
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double r = math.min(size.width, size.height) * 0.36;
    final Offset center = Offset(size.width / 2, size.height * 0.48);
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    const int dashes = 56;
    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), i * 2 * math.pi / dashes, math.pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

/// Audio-style bars: they bounce while moving and are solid up to [filled].
class _WavePainter extends CustomPainter {
  final double filled;
  final double phase;
  final bool moving;
  final Color color;
  _WavePainter({required this.filled, required this.phase, required this.moving, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const int bars = 36;
    final double gap = size.width / bars;
    final paint = Paint()..strokeCap = StrokeCap.round..strokeWidth = math.max(2, gap * 0.45);
    for (int i = 0; i < bars; i++) {
      final double base = 0.35 + 0.55 * (0.5 + 0.5 * math.sin(i * 1.7) * math.cos(i * 0.6)).abs();
      final double bounce = moving ? 0.7 + 0.45 * math.sin(phase * math.pi * 2 + i) : 1;
      final double h = (size.height * base * bounce).clamp(4.0, size.height);
      paint.color = (i / bars) < filled ? color : color.withValues(alpha: 0.25);
      final double x = gap * (i + 0.5);
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.filled != filled || old.phase != phase || old.moving != moving || old.color != color;
}

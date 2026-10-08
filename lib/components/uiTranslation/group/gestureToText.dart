import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/sign_recognizer.dart';
import 'package:signlang/services/theme_service.dart';

enum _Phase { idle, recording, processing, result }

/// Gesture → Text: records the user's sign with the camera for the chosen time, shows the recognized
/// text and can read it out loud (highlighting the word being spoken).
class GestureToText extends StatefulWidget {
  const GestureToText({super.key});

  @override
  State<GestureToText> createState() => _GestureToTextState();
}

class _GestureToTextState extends State<GestureToText> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const Color _blue = Color(0xFF4A7FD0);
  static const Color _liveRed = Color(0xFFAE3A12);
  static const Color _green = Color(0xFF16A34A);
  static const Color _white = Color(0xFFFFFFFF);
  static const List<int> _durations = [3, 5, 8, 10];

  // ===== camera =====
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _camera;
  bool _cameraDenied = false;
  bool _flashOn = false;

  // ===== recording / result =====
  _Phase _phase = _Phase.idle;
  int _seconds = 3;
  int _left = 0;
  Timer? _countdown;
  String _text = '';
  bool _notRecognized = false;

  // ===== voice =====
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  int _wordStart = 0, _wordEnd = 0;
  double _progress = 0;
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  // ===== font =====
  double _fontSize = 22;
  int _weight = 2; // 0 light, 1 medium, 2 bold
  static const List<FontWeight> _weights = [FontWeight.w300, FontWeight.w500, FontWeight.w700];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initTts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdown?.cancel();
    _camera?.dispose();
    _tts.stop();
    _wave.dispose();
    super.dispose();
  }

  // the camera must be released while the app is in the background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_phase == _Phase.recording) _cancelRecording();
      final camera = _camera;
      _camera = null;
      camera?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _camera == null) { _initCamera(); }
  }

// ======================== camera ========================
  Future<void> _initCamera() async {
    // TODO: API_VIDEOS_TO_SIGN_LANG
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        final front = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        _cameraIndex = front >= 0 ? front : 0;
      }
      if (_cameras.isEmpty) return;
      final controller = CameraController(_cameras[_cameraIndex], ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) { controller.dispose(); return; }
      await _camera?.dispose();
      setState(() { _camera = controller; _cameraDenied = false; _flashOn = false; });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _cameraDenied = e.code.contains('AccessDenied') || e.code.contains('Permission'));
    }
  }

  Future<void> _toggleFlash() async {
    final camera = _camera;
    if (camera == null) return;
    try {
      await camera.setFlashMode(_flashOn ? FlashMode.off : FlashMode.torch);
      setState(() => _flashOn = !_flashOn);
    } on CameraException {
      // front cameras usually have no torch
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _phase == _Phase.recording || _phase == _Phase.processing) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    final old = _camera;
    setState(() => _camera = null);
    await old?.dispose();
    await _initCamera();
  }

// ======================== recording ========================
  Future<void> _start() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) { _initCamera(); return; }
    await _stopSpeaking();
    setState(() { _phase = _Phase.recording; _left = _seconds; _text = ''; _notRecognized = false; _progress = 0; });
    try { await camera.startVideoRecording(); } on CameraException { /* recognition can still run without a clip */ }
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _left--);
      if (_left <= 0) _stop();
    });
  }

  Future<void> _stop() async {
    if (_phase != _Phase.recording) return;
    _countdown?.cancel();
    final loc = AppLocalizations.of(context)!;
    setState(() => _phase = _Phase.processing);
    XFile? clip;
    try { if (_camera?.value.isRecordingVideo ?? false) clip = await _camera!.stopVideoRecording(); } on CameraException { clip = null; }
    final text = await SignRecognizer.recognize(clip: clip, debugDemoText: loc.translate('gt_demo_result')); // TODO: API_WRITE
    if (!mounted) return;
    setState(() { _phase = _Phase.result; _text = text ?? ''; _notRecognized = text == null || text.isEmpty; });
  }

  void _cancelRecording() {
    _countdown?.cancel();
    try { _camera?.stopVideoRecording(); } catch (_) {}
    _phase = _Phase.idle;
  }

  Future<void> _retake() async {
    await _stopSpeaking();
    setState(() { _phase = _Phase.idle; _text = ''; _notRecognized = false; _progress = 0; });
  }

  void _onMainButton() {
    switch (_phase) {
      case _Phase.recording: _stop();
      case _Phase.processing: break;
      case _Phase.result: _retake().then((_) => _start());
      case _Phase.idle: _start();
    }
  }

// ======================== voice ========================
  Future<void> _initTts() async {
    _tts.setProgressHandler((text, start, end, word) {
      if (!mounted) return;
      setState(() { _wordStart = start; _wordEnd = end; _progress = text.isEmpty ? 0 : end / text.length; });
    });
    _tts.setCompletionHandler(() { if (mounted) setState(() { _speaking = false; _progress = 1; _wordStart = _wordEnd = 0; }); _wave.stop(); });
    _tts.setCancelHandler(() { if (mounted) setState(() => _speaking = false); _wave.stop(); });
    _tts.setErrorHandler((_) { if (mounted) setState(() => _speaking = false); _wave.stop(); });
  }

  Future<void> _toggleSpeak() async {
    if (_text.isEmpty) return; if (_speaking) return _stopSpeaking(); final code = Localizations.localeOf(context).languageCode;
    final lang = switch (code) { 'uz' => 'uz-UZ', 'ru' => 'ru-RU', _ => 'en-US' };
    try { if (await _tts.isLanguageAvailable(lang) == true) await _tts.setLanguage(lang); } catch (_) {}
    setState(() { _speaking = true; _progress = 0; _wordStart = _wordEnd = 0; });
    _wave.repeat(reverse: true); await _tts.speak(_text);
  }

  Future<void> _stopSpeaking() async { await _tts.stop(); _wave.stop(); if (mounted) setState(() { _speaking = false; _wordStart = _wordEnd = 0; }); }

  void _copy() {
    if (_text.isEmpty) return; Clipboard.setData(ClipboardData(text: _text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.translate('gt_copied')), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)));
  }

// ======================================================
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final c = AppColors.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.bgGradient)),
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
                    Expanded(child: Text(loc.translate('gesture_text'), textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text))),
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
                      // ===== 2) duration =====
                      Text(loc.translate('gt_duration'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 8), _durationChips(), const SizedBox(height: 12),
                      // ===== 3) camera =====
                      _cameraView(loc), const SizedBox(height: 14),
                      // ===== 4) controls =====
                      _controls(), const SizedBox(height: 14),
                      // ===== 5) recognized text =====
                      _detectedCard(loc, c), const SizedBox(height: 12),
                      // ===== 6) voice =====
                      _voiceCard(loc, c), const SizedBox(height: 12),
                      // ===== 7) font =====
                      _fontCard(loc, c), const SizedBox(height: 12),
                      // ===== 8) tip =====
                      _tipCard(loc, c), const SizedBox(height: 16),
                      // ===== 9) main button =====
                      _mainButton(loc, c),
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

  Widget _durationChips() {
    final bool locked = _phase == _Phase.recording || _phase == _Phase.processing;
    return Row(
      children: [
        for (final s in _durations) ...[
          Expanded(
            child: GestureDetector(
              onTap: locked ? null : () => setState(() => _seconds = s),
              child: Container(
                height: 40, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _seconds == s ? AppPalette.bg(_blue).withValues(alpha: 0.7) : AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppPalette.border(Colors.white)),
                ),
                child: Text('${s}s', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _seconds == s ? Colors.white : AppPalette.fg(const Color(0xFF475569)))),
              ),
            ),
          ),
          if (s != _durations.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _cameraView(AppLocalizations loc) {
    final camera = _camera;
    final bool ready = camera != null && camera.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 360, width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF4A5A66)),
            if (ready)
              FittedBox(
                fit: BoxFit.cover,
                // preview size is landscape; the phone is held upright
                child: SizedBox(width: camera.value.previewSize?.height ?? 1, height: camera.value.previewSize?.width ?? 1, child: CameraPreview(camera)),
              )
            else
              Center(
                child: _cameraDenied
                  ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 44), const SizedBox(height: 10),
                        Text(loc.translate('gt_camera_denied'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _initCamera,
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          child: Text(loc.translate('gt_allow_camera')),
                        ),
                      ],
                    ),
                  ) : const CircularProgressIndicator(color: Colors.white),
              ),
            // dashed guide circle
            IgnorePointer(child: CustomPaint(painter: _DashedCirclePainter(color: Colors.white.withValues(alpha: 0.85)))),
            // LIVE pill + seconds left
            if (_phase == _Phase.recording)
              Positioned(
                top: 14, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFBBF7D0), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text('LIVE · ${_left}s', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                      ]
                    )
                  )
                )
              ),
            // recognizing...
            if (_phase == _Phase.processing)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white), const SizedBox(height: 10),
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

  Widget _controls() {
    final bool recording = _phase == _Phase.recording;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _roundIconButton(_flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, _toggleFlash, active: _flashOn),
        GestureDetector(
          onTap: _phase == _Phase.processing ? null : _onMainButton,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppPalette.bg(recording ? _liveRed : _blue), shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppPalette.shadow(recording ? _liveRed : _blue).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Icon(recording ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 34),
          ),
        ),
        _roundIconButton(Icons.cameraswitch_rounded, _switchCamera),
      ],
    );
  }

  Widget _roundIconButton(IconData icon, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: active ? AppPalette.bg(const Color(0xFFFFF3C4)) : AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: AppPalette.fg(const Color(0xFF475569))),
      ),
    );
  }

  BoxDecoration _cardDecoration(AppColors c) => BoxDecoration(
    color: c.isDark ? c.card : Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20),
    border: Border.all(color: c.cardBorder), boxShadow: [BoxShadow(color: c.glow.withValues(alpha: c.isDark? 0.3 : 0.9), blurRadius: 15, offset: const Offset(0, 4))],
  );

  Widget _label(String text) => Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.fg(_white)));

  // text with the currently spoken word in bold
  InlineSpan _highlighted(TextStyle base, Color strong) {
    if (_wordEnd <= _wordStart || _wordEnd > _text.length) return TextSpan(text: _text, style: base);
    return TextSpan(style: base, children: [
      TextSpan(text: _text.substring(0, _wordStart)),
      TextSpan(text: _text.substring(_wordStart, _wordEnd), style: TextStyle(fontWeight: FontWeight.w800, color: strong)),
      TextSpan(text: _text.substring(_wordEnd)),
    ]);
  }

  Widget _detectedCard(AppLocalizations loc, AppColors c) {
    final bool empty = _text.isEmpty;
    final TextStyle base = TextStyle(fontSize: _fontSize, fontWeight: _weights[_weight], height: 1.3, color: empty ? AppPalette.fg(const Color(0xFF000000).withValues(alpha: 0.3)) : c.subText);
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 12, 14, 14), decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(loc.translate('gt_detected'))),
              GestureDetector(onTap: _copy, child: Icon(Icons.copy_rounded, size: 18, color: AppPalette.fg(empty ? const Color(0xFF000000).withValues(alpha: 0.9) : const Color(0xFF64748B).withValues(alpha: 0.9)))),
            ],
          ),
          const SizedBox(height: 8),
          if (empty)
            Text(loc.translate(_notRecognized ? 'gt_not_recognized' : 'gt_detected_hint'), style: _notRecognized ? base.copyWith(fontSize: 15, color: AppPalette.fg(const Color(0xFFD32F2F))) : base)
          else
            Text.rich(_highlighted(base, c.text.withValues(alpha: 0.2))),
        ],
      ),
    );
  }

  Widget _voiceCard(AppLocalizations loc, AppColors c) {
    final bool hasText = _text.isNotEmpty;
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 12, 14, 14), decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(loc.translate('gt_voice'))),
              if (_speaking)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFFEF9C3)), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, size: 13, color: AppPalette.fg(const Color(0xFF854D0E))), const SizedBox(width: 3),
                      Text(loc.translate('gt_reading'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.fg(const Color(0xFF854D0E))))
                    ]
                  )
                )
            ]
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.isDark ? c.chip : Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: hasText ? _toggleSpeak : null,
                  child: Container(
                    width: 40, height: 40, decoration: BoxDecoration(color: AppPalette.bg(hasText ? _blue : const Color(0xFF9DB7E2)), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_speaking ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: SizedBox(height: 30, child: AnimatedBuilder(animation: _wave, builder: (_, _) => CustomPaint(painter: _WavePainter(progress: _progress, phase: _wave.value, playing: _speaking, color: AppPalette.fg(_blue)))))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (hasText)
            Text.rich(_highlighted(TextStyle(fontSize: 15, color: c.subText), c.text))
          else
            Text(loc.translate('gt_voice_hint'), style: TextStyle(fontSize: 14, color: AppPalette.fg(const Color(0xFF000000).withValues(alpha: 0.6)))),
          if (hasText && (_speaking || _progress > 0)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: _progress.clamp(0.0, 1.0), minHeight: 8, backgroundColor: AppPalette.bg(const Color(0xFFDCFCE7)), valueColor: AlwaysStoppedAnimation(AppPalette.fg(_green))),
                  ),
                ),
                const SizedBox(width: 10), Text('${(_progress * 100).clamp(0, 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppPalette.fg(_green)))
              ]
            )
          ]
        ]
      )
    );
  }

  Widget _fontCard(AppLocalizations loc, AppColors c) {
    final weightLabels = [loc.translate('gt_light'), loc.translate('gt_medium'), loc.translate('gt_bold')];
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 12, 14, 14), decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(loc.translate('gt_font_size')),
          Row(
            children: [
              Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2, activeTrackColor: AppPalette.fg(const Color(0xFFCBD5E1)), inactiveTrackColor: AppPalette.fg(const Color(0xFFCBD5E1)), thumbColor: Colors.white,
                    overlayColor: AppPalette.fg(_blue).withValues(alpha: 0.1), thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 3)
                  ),
                  child: Slider(value: _fontSize, min: 14, max: 34, onChanged: (v) => setState(() => _fontSize = v)),
                ),
              ),
              Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            ],
          ),
          const SizedBox(height: 4),
          Text(loc.translate('gt_font_weight'), style: TextStyle(fontSize: 13, color: c.text)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
              boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)]
            ),
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
                        child: Text(weightLabels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: _weight == i ? FontWeight.w700 : FontWeight.w400, color: _weight == i ? c.text : c.subText))
                      )
                    )
                  )
              ]
            )
          )
        ]
      )
    );
  }

  Widget _tipCard(AppLocalizations loc, AppColors c) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFFFFCC80)).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFFFC107)).withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFFFFCC80)).withValues(alpha: 0.9), blurRadius: 15)]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFFFF176).withValues(alpha: 0.6)), border: Border.all(width: 1, color: AppPalette.border(Colors.yellow)), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.info_rounded, size: 20, color: AppPalette.fg(const Color(0xFFF59E0B))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.translate('gt_tip_title'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                const SizedBox(height: 4),
                Text(loc.translate('gt_tip'), style: TextStyle(fontSize: 15, height: 1.4, color: c.text.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainButton(AppLocalizations loc, AppColors c) {
    if (_phase == _Phase.result) {
      return SizedBox(
        width: double.infinity, height: 54,
        child: TextButton.icon(
          onPressed: _retake,
          icon: Icon(Icons.refresh_rounded, color: c.subText),
          label: Text(loc.translate('gt_retake'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.subText)),
          style: TextButton.styleFrom(
            backgroundColor: c.isDark ? c.chip : Colors.white.withValues(alpha: 0.6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 6,
            side: BorderSide(width: 1, color: c.isDark ? c.chip : Color(0xFF1A237E).withValues(alpha: 0.2)), shadowColor: c.isDark ? c.chip : Colors.grey.withValues(alpha: 0.9),
          ),
        ),
      );
    }
    final bool busy = _phase != _Phase.idle;
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: busy ? null : _start,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.bg(_blue).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), shadowColor: AppPalette.bg(_blue).withValues(alpha: 0.9),
          disabledBackgroundColor: AppPalette.bg(_blue).withValues(alpha: 0.5), disabledForegroundColor: Colors.white,
          elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(loc.translate('gt_translate'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    final double r = size.width * 0.3;
    final Offset center = Offset(size.width / 2, size.height * 0.45);
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    const int dashes = 60;
    for (int i = 0; i < dashes; i++) {
      final double start = i * 2 * math.pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, math.pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

/// Audio-style bars; the part already spoken is solid, bars bounce while playing.
class _WavePainter extends CustomPainter {
  final double progress;
  final double phase;
  final bool playing;
  final Color color;
  _WavePainter({required this.progress, required this.phase, required this.playing, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const int bars = 34;
    final double gap = size.width / bars;
    final paint = Paint()..strokeCap = StrokeCap.round..strokeWidth = math.max(2, gap * 0.45);
    for (int i = 0; i < bars; i++) {
      final double base = 0.35 + 0.55 * (0.5 + 0.5 * math.sin(i * 1.7) * math.cos(i * 0.6)).abs();
      final double bounce = playing ? 0.85 + 0.3 * math.sin(phase * math.pi * 2 + i) : 1;
      final double h = (size.height * base * bounce).clamp(4.0, size.height);
      paint.color = (i / bars) < progress ? color : color.withValues(alpha: 0.25);
      final double x = gap * (i + 0.5);
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress || old.phase != phase || old.playing != playing || old.color != color;
}

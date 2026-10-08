import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/sign_lookup.dart';
import 'package:signlang/services/theme_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:video_player/video_player.dart';

/// Text → Gesture: type or say a sentence and watch it signed, word by word
/// (own sign video when the word has one, otherwise fingerspelled letter by letter).
class TextToGesture extends StatefulWidget {
  /// Text to sign right away, e.g. a transcript sent from Speech → Text.
  final String? initialText;
  const TextToGesture({super.key, this.initialText});

  @override
  State<TextToGesture> createState() => _TextToGestureState();
}

class _TextToGestureState extends State<TextToGesture> with SingleTickerProviderStateMixin {
  static const Color _blue = Color(0xFF4A7FD0);
  static const Color _green = Color(0xFF16A34A);
  static const Color _white = Color(0xFFFFFFFF);
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25];
  static const int _maxLength = 200;

  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  // ===== voice input =====
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;
  double _level = 0;
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  // ===== sequence / player =====
  String _signedText = ''; // the text that was translated (shown with the current word in bold)
  List<SignWord> _words = [];
  List<SignStep> _steps = [];
  int _index = -1;
  VideoPlayerController? _video;
  VideoPlayerController? _preloaded;
  int _preloadedIndex = -1;
  bool _playing = false;
  bool _finished = false;
  double _speed = 1.0;
  bool _showMissing = false;
  int _playToken = 0; // invalidates callbacks from older steps when the user jumps around

  // ===== font =====
  double _fontSize = 20;
  int _weight = 1;
  static const List<FontWeight> _weights = [FontWeight.w300, FontWeight.w500, FontWeight.w700];

  bool get _hasResult => _words.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    final initial = widget.initialText?.trim() ?? '';
    if (initial.isNotEmpty) {
      _input.text = initial.length > _maxLength ? initial.substring(0, _maxLength) : initial;
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _translate(); });
    }
  }

  @override
  void dispose() {
    _playToken++;
    _video?.dispose();
    _preloaded?.dispose();
    _speech.cancel();
    _wave.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

// ======================== translate ========================
  void _translate() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _inputFocus.unfocus();
    if (_listening) _stopListening();
    final words = SignLookup.translate(text);
    setState(() { _signedText = text; _words = words; _steps = [for (final w in words) ...w.steps]; _finished = false; });
    if (_steps.isNotEmpty) _playFrom(0);
  }

  /// "Qayta yozish": back to an empty input, ready to type again.
  void _rewrite() {
    _playToken++;
    _video?.pause();
    _preloaded?.dispose(); _preloaded = null; _preloadedIndex = -1;
    _input.clear();
    setState(() { _signedText = ''; _words = []; _steps = []; _index = -1; _playing = false; _finished = false; _showMissing = false; });
    _inputFocus.requestFocus();
  }

// ======================== player ========================
  Future<VideoPlayerController?> _load(int i) async {
    final path = _steps[i].video;
    if (path == null) return null;
    // muted sign videos: never take audio focus (speech or other videos would pause them)
    final controller = VideoPlayerController.asset(path, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    try {
      await controller.initialize();
      await controller.setPlaybackSpeed(_speed);
      return controller;
    } catch (_) {
      controller.dispose();
      return null;
    }
  }

  Future<void> _playFrom(int i) async {
    if (i >= _steps.length) {
      setState(() { _playing = false; _finished = true; });
      return;
    }
    final token = ++_playToken;
    final old = _video;
    VideoPlayerController? next;
    if (_preloadedIndex == i && _preloaded != null) {
      next = _preloaded;
      _preloaded = null; _preloadedIndex = -1;
      await next!.setPlaybackSpeed(_speed);
    } else {
      setState(() { _index = i; _playing = true; _finished = false; });
      next = await _load(i);
    }
    if (!mounted || token != _playToken) { if (next != _video) next?.dispose(); return; }

    setState(() { _index = i; _video = next; _playing = true; _finished = false; _showMissing = next == null; });
    if (old != null && old != next) old.dispose();

    if (next == null) {
      // no sign for this letter/word: show it briefly, then move on
      Future.delayed(const Duration(milliseconds: 900), () { if (mounted && token == _playToken && _playing) _playFrom(i + 1); });
      return;
    }
    next.addListener(() {
      final v = next!.value;
      if (token == _playToken && v.isInitialized && !v.isPlaying && v.position >= v.duration && v.duration > Duration.zero) {
        _playToken++; // finish once
        _playFrom(i + 1);
      }
    });
    await next.play();
    _preload(i + 1);
  }

  Future<void> _preload(int i) async {
    if (i >= _steps.length || _preloadedIndex == i) return;
    _preloaded?.dispose();
    _preloaded = null; _preloadedIndex = -1;
    final controller = await _load(i);
    if (!mounted) { controller?.dispose(); return; }
    _preloaded = controller; _preloadedIndex = controller == null ? -1 : i;
  }

  void _replay() { if (_steps.isNotEmpty) _playFrom(0); }

  // tap on the video: pause / continue
  void _togglePause() {
    if (_steps.isEmpty) return;
    if (_finished) return _replay();
    final video = _video;
    if (_playing) {
      video?.pause();
      setState(() => _playing = false);
    } else if (video != null) {
      video.play();
      setState(() => _playing = true);
    } else { _playFrom(_index); }
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _video?.setPlaybackSpeed(speed);
    _preloaded?.setPlaybackSpeed(speed);
  }

  void _cycleSpeed() => _setSpeed(_speeds[(_speeds.indexOf(_speed) + 1) % _speeds.length]);

  // "Burchak": the video full screen
  Future<void> _openFullScreen() async {
    final video = _video;
    if (video == null || !video.value.isInitialized) return;
    await Navigator.push(context, PageRouteBuilder(
      opaque: false, barrierColor: Colors.black,
      pageBuilder: (_, _, _) => _FullScreenSign(controller: video, label: _index >= 0 && _index < _steps.length ? _steps[_index].label : ''),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ));
    if (mounted) setState(() {});
  }

// ======================== voice input ========================
  Future<void> _toggleListening() async {
    if (_listening) return _stopListening();
    final available = await _speech.initialize(onStatus: (s) { if (mounted && (s == 'done' || s == 'notListening')) { _wave.stop(); setState(() => _listening = false); } });
    if (!available || !mounted) return;
    final code = Localizations.localeOf(context).languageCode;
    final wanted = switch (code) { 'uz' => 'uz_UZ', 'ru' => 'ru_RU', _ => 'en_US' };
    final locales = await _speech.locales();
    final localeId = locales.any((l) => l.localeId == wanted) ? wanted : null;
    if (_hasResult) _rewrite();
    setState(() => _listening = true);
    _wave.repeat(reverse: true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: localeId, listenMode: ListenMode.dictation, autoPunctuation: true),
      onSoundLevelChange: (level) { if (mounted) setState(() => _level = _level * 0.6 + ((level + 2) / 12).clamp(0.0, 1.0) * 0.4); },
      onResult: (r) {
        if (!mounted) return;
        _input.text = r.recognizedWords.length > _maxLength ? r.recognizedWords.substring(0, _maxLength) : r.recognizedWords;
        _input.selection = TextSelection.collapsed(offset: _input.text.length);
        if (r.finalResult) { _stopListening(); _translate(); }
      },
    );
  }

  Future<void> _stopListening() async {
    _wave.stop();
    await _speech.stop();
    if (mounted) setState(() { _listening = false; _level = 0; });
  }

// ======================== text with the current word in bold ========================
  /// Original typed words (keeps capitals / punctuation), grouped like the sign words.
  List<String> get _displayWords {
    final typed = _signedText.split(RegExp(r'\s+')).where((t) => SignLookup.normalize(t).isNotEmpty).toList();
    final out = <String>[];
    int t = 0;
    for (final w in _words) {
      final end = math.min(t + w.tokens, typed.length);
      out.add(t < end ? typed.sublist(t, end).join(' ') : w.text);
      t = end;
    }
    return out;
  }

  int get _currentWord => _index >= 0 && _index < _steps.length && !_finished ? _steps[_index].word : -1;

  InlineSpan _signedSpan(TextStyle base, Color strong) {
    final words = _displayWords;
    final current = _currentWord;
    return TextSpan(style: base, children: [
      for (int i = 0; i < words.length; i++)
        TextSpan(text: i == 0 ? words[i] : ' ${words[i]}', style: i == current ? TextStyle(fontWeight: FontWeight.w800, color: strong) : null),
    ]);
  }

  double get _signedProgress => _steps.isEmpty ? 0 : (_finished ? 1 : (_index + 1) / _steps.length);

// ======================== text edit sheet ========================
  Future<void> _openTextSettings() async {
    double size = _fontSize; int weight = _weight; double speed = _speed;
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
                _fontControls(loc, c, size, weight, (v) => setSheet(() => size = v), (v) => setSheet(() => weight = v)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: Text(loc.translate('tg_speed'), style: TextStyle(fontSize: 13, color: c.subText))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFE2E8F0)).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: speed, isDense: true, borderRadius: BorderRadius.circular(12),
                          items: [for (final s in _speeds) DropdownMenuItem(value: s, child: Text(_speedLabel(s), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)))],
                          onChanged: (v) { if (v != null) setSheet(() => speed = v); },
                        ),
                      ),
                    ),
                  ],
                ),
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
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: Text(loc.translate('cancel'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.text)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (apply == true && mounted) {
      setState(() { _fontSize = size; _weight = weight; });
      if (speed != _speed) _setSpeed(speed);
    }
  }

  static String _speedLabel(double s) => '${s == s.roundToDouble() ? s.toInt() : s}x';

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
                    Expanded(child: Text(loc.translate('text_gesture'), textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text))),
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
                      // ===== 2) sign video =====
                      _player(loc, c),
                      const SizedBox(height: 10),
                      // ===== 3) again / speed / corner =====
                      _videoActions(loc),
                      const SizedBox(height: 12),
                      // ===== 4) write text =====
                      _inputCard(loc, c),
                      const SizedBox(height: 12),
                      // ===== 5) voice =====
                      _voiceCard(loc, c),
                      const SizedBox(height: 12),
                      // ===== 6) font =====
                      Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 12, 14, 14), decoration: _cardDecoration(c), child: _fontControls(loc, c, _fontSize, _weight, (v) => setState(() => _fontSize = v), (v) => setState(() => _weight = v))),
                      const SizedBox(height: 12),
                      // ===== 7) tip =====
                      _tipCard(loc, c),
                      const SizedBox(height: 16),
                      // ===== 8) main button =====
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

  Widget _player(AppLocalizations loc, AppColors c) {
    final video = _video;
    final SignStep? step = _index >= 0 && _index < _steps.length ? _steps[_index] : null;
    final bool showVideo = video != null && video.value.isInitialized && !_showMissing;

    return GestureDetector(
      onTap: _togglePause,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 300, width: double.infinity, decoration: BoxDecoration(color: c.isDark ? c.card : AppPalette.bg(const Color(0xFFE9EEF7)), border: Border.all(color: c.cardBorder), borderRadius: BorderRadius.circular(22)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showVideo)
                FittedBox(fit: BoxFit.contain, child: SizedBox(width: video.value.size.width, height: video.value.size.height, child: VideoPlayer(video)))
              else if (step == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sign_language_rounded, size: 56, color: AppPalette.fg(_blue).withValues(alpha: 0.55)), const SizedBox(height: 10),
                        Text(loc.translate('tg_player_hint'), textAlign: TextAlign.center, style: TextStyle(color: c.subText, fontSize: 14, height: 1.4)),
                      ],
                    ),
                  ),
                )
              else if (_showMissing)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(step.label, style: TextStyle(color: c.text, fontSize: 46, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6), Text(loc.translate('tg_no_sign'), style: TextStyle(color: c.subText, fontSize: 14)),
                    ],
                  ),
                )
              else
                Center(child: CircularProgressIndicator(color: AppPalette.fg(_blue))),
              // current word / letter
              if (step != null && !_finished)
                Positioned(
                  top: 12, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 7, height: 7, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)), const SizedBox(width: 6),
                          Text(step.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ),
                ),
              // paused / finished
              if (_steps.isNotEmpty && !_playing)
                Center(
                  child: Container(
                    width: 58, height: 58, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                    child: Icon(_finished ? Icons.replay_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 34),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoActions(AppLocalizations loc) {
    Widget pill(IconData icon, String text, VoidCallback? onTap) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40, decoration: BoxDecoration(
            color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppPalette.border(Colors.white)),
            boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFFBDBDBD)).withValues(alpha: 0.9), blurRadius: 15)]
        ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: AppPalette.fg(onTap == null ? const Color(0xFFB6C0CC) : const Color(0xFF475569))), const SizedBox(width: 6),
              Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.fg(onTap == null ? const Color(0xFFB6C0CC) : const Color(0xFF334155))))),
            ],
          ),
        ),
      ),
    );
    final bool hasVideo = _video != null && !_showMissing;
    return Row(
      children: [
        pill(Icons.refresh_rounded, loc.translate('again'), _steps.isEmpty ? null : _replay),
        const SizedBox(width: 8),
        pill(Icons.speed_rounded, _speedLabel(_speed), _cycleSpeed),
        const SizedBox(width: 8),
        pill(Icons.call_made_rounded, loc.translate('corner'), hasVideo ? _openFullScreen : null),
      ],
    );
  }

  BoxDecoration _cardDecoration(AppColors c) => BoxDecoration(
    color: c.isDark ? c.card : Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20),
    border: Border.all(color: c.cardBorder), boxShadow: [BoxShadow(color: c.glow.withValues(alpha: c.isDark? 0.3 : 0.9), blurRadius: 15, offset: const Offset(0, 4))],
  );

  Widget _label(String text) => Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppPalette.fg(_white)));

  Widget _inputCard(AppLocalizations loc, AppColors c) {
    final TextStyle style = TextStyle(fontSize: _fontSize, fontWeight: _weights[_weight], height: 1.3, color: c.text);
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 12, 10, 12), decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(loc.translate('tg_input'))),
              GestureDetector(onTap: _openTextSettings, child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.text_fields_rounded, size: 19, color: AppPalette.fg(const Color(0xFF000000).withValues(alpha: 0.9))))),
            ],
          ),
          const SizedBox(height: 4),
          if (_hasResult)
            // signed text: the word being shown right now is bold
            GestureDetector(onTap: _rewrite, child: Padding(padding: const EdgeInsets.only(right: 4, top: 4, bottom: 4), child: Text.rich(_signedSpan(style.copyWith(color: c.subText), c.text))))
          else
            TextField(
              controller: _input, focusNode: _inputFocus, minLines: 1, maxLines: 4, maxLength: _maxLength,
              textInputAction: TextInputAction.done, onSubmitted: (_) => _translate(), style: style,
              decoration: InputDecoration(
                border: InputBorder.none, isDense: true, counterText: '',
                hintText: loc.translate('tg_input_hint'), hintStyle: style.copyWith(color: AppPalette.fg(const Color(0xFFF5F5F5)), fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _voiceCard(AppLocalizations loc, AppColors c) {
    final bool active = _listening || _hasResult;
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(loc.translate('tg_voice'))),
              if (_listening || (_hasResult && _playing))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFFEF9C3)), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_listening ? Icons.mic_rounded : Icons.sign_language_rounded, size: 13, color: AppPalette.fg(const Color(0xFF854D0E))),
                      const SizedBox(width: 3),
                      Text(loc.translate(_listening ? 'tg_listening' : 'tg_signing'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.fg(const Color(0xFF854D0E)))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.isDark ? c.chip : Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppPalette.bg(_blue), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: AnimatedBuilder(
                      animation: _wave,
                      builder: (_, _) => CustomPaint(painter: _WavePainter(
                        filled: _listening ? 0.35 + 0.65 * _level : _signedProgress,
                        phase: _wave.value, moving: _listening, color: AppPalette.fg(_blue),
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_hasResult)
            Text.rich(_signedSpan(TextStyle(fontSize: 14, color: c.subText), c.text))
          else
            Text(loc.translate(_listening ? 'tg_listening' : 'tg_voice_hint'), style: TextStyle(fontSize: 13, height: 1.4, color: AppPalette.fg(const Color(0xFFFFFFFF).withValues(alpha: 0.6)))),
          if (_hasResult && active) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: _signedProgress, minHeight: 8, backgroundColor: AppPalette.bg(const Color(0xFFDCFCE7)), valueColor: AlwaysStoppedAnimation(AppPalette.fg(_green))),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${(_signedProgress * 100).round()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppPalette.fg(_green))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _fontControls(AppLocalizations loc, AppColors c, double size, int weight, ValueChanged<double> onSize, ValueChanged<int> onWeight) {
    final weightLabels = [loc.translate('gt_light'), loc.translate('gt_medium'), loc.translate('gt_bold')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(loc.translate('gt_font_size')),
        Row(
          children: [
            Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.subText)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(trackHeight: 2, activeTrackColor: AppPalette.fg(const Color(0xFFCBD5E1)), inactiveTrackColor: AppPalette.fg(const Color(0xFFCBD5E1)), thumbColor: Colors.white, overlayColor: AppPalette.fg(_blue).withValues(alpha: 0.1), thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 3)),
                child: Slider(value: size, min: 14, max: 34, onChanged: onSize),
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
                    onTap: () => onWeight(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: weight == i ? AppPalette.bg(Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(11),
                        boxShadow: weight == i ? [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : null,
                      ),
                      child: Text(weightLabels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: weight == i ? FontWeight.w700 : FontWeight.w400, color: weight == i ? c.text : c.subText)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
                Text(loc.translate('tg_tip'), style: TextStyle(fontSize: 13, height: 1.4, color: c.subText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainButton(AppLocalizations loc, AppColors c) {
    if (_hasResult) {
      return SizedBox(
        width: double.infinity, height: 54,
        child: TextButton.icon(
          onPressed: _rewrite,
          icon: Icon(Icons.refresh_rounded, color: c.subText),
          label: Text(loc.translate('gt_retake'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.subText)),
          style: TextButton.styleFrom(backgroundColor: c.isDark ? c.chip : Colors.white.withValues(alpha: 0.6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        ),
      );
    }
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: _input.text.trim().isEmpty ? null : _translate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.bg(_blue), foregroundColor: Colors.white, disabledBackgroundColor: AppPalette.bg(_blue).withValues(alpha: 0.45), disabledForegroundColor: Colors.white,
          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(loc.translate('gt_translate'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// "Burchak": the current sign video over the whole screen; tap anywhere to close.
class _FullScreenSign extends StatelessWidget {
  final VideoPlayerController controller;
  final String label;
  const _FullScreenSign({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller))),
              Positioned(
                top: 12, right: 12,
                child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ),
              if (label.isNotEmpty)
                Positioned(
                  left: 0, right: 0, bottom: 24,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Audio-style bars: while listening they bounce with the voice, afterwards they fill with the signing progress.
class _WavePainter extends CustomPainter {
  final double filled;
  final double phase;
  final bool moving;
  final Color color;
  _WavePainter({required this.filled, required this.phase, required this.moving, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const int bars = 34;
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

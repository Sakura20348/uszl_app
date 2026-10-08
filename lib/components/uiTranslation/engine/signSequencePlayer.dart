import 'package:flutter/material.dart';
import 'package:signlang/services/sign_lookup.dart';
import 'package:signlang/services/theme_service.dart';
import 'package:video_player/video_player.dart';

/// Plays the sign videos of a translated sentence one after another
/// (the next one is preloaded so there is no gap between words).
class SignSequencePlayer extends ChangeNotifier {
  List<SignWord> words = [];
  List<SignStep> steps = [];
  int index = -1;
  VideoPlayerController? video;
  VideoPlayerController? _preloaded;
  int _preloadedIndex = -1;
  bool playing = false;
  bool finished = false;
  bool showMissing = false; // current step has no video: its label is shown instead
  double speed = 1.0;
  int _token = 0; // invalidates callbacks of older steps
  bool _disposed = false;

  bool get isEmpty => steps.isEmpty;
  SignStep? get currentStep => index >= 0 && index < steps.length ? steps[index] : null;
  int get currentWord => currentStep != null && !finished ? currentStep!.word : -1;
  double get progress => steps.isEmpty ? 0 : (finished ? 1 : (index + 1) / steps.length);

  void _notify() { if (!_disposed) notifyListeners(); }

  void load(List<SignWord> newWords, {bool autoplay = true}) {
    stop();
    words = newWords;
    steps = [for (final w in newWords) ...w.steps];
    index = -1; finished = false; showMissing = false;
    _notify();
    if (autoplay && steps.isNotEmpty) playFrom(0);
  }

  void clear() {
    stop();
    video?.dispose(); video = null;
    words = []; steps = []; index = -1; finished = false; showMissing = false;
    _notify();
  }

  Future<VideoPlayerController?> _load(int i) async {
    final path = steps[i].video;
    if (path == null) return null;
    // muted sign videos: never take audio focus (speech or other videos would pause them)
    final controller = VideoPlayerController.asset(path, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    try {
      await controller.initialize();
      await controller.setPlaybackSpeed(speed);
      return controller;
    } catch (_) {
      controller.dispose();
      return null;
    }
  }

  Future<void> playFrom(int i) async {
    if (_disposed) return;
    if (i >= steps.length) { playing = false; finished = true; _notify(); return; }
    final token = ++_token;
    final old = video;
    VideoPlayerController? next;
    if (_preloadedIndex == i && _preloaded != null) {
      next = _preloaded;
      _preloaded = null; _preloadedIndex = -1;
      await next!.setPlaybackSpeed(speed);
    } else {
      index = i; playing = true; finished = false; _notify();
      next = await _load(i);
    }
    if (_disposed || token != _token) { if (next != video) next?.dispose(); return; }

    index = i; video = next; playing = true; finished = false; showMissing = next == null;
    _notify();
    if (old != null && old != next) old.dispose();

    if (next == null) {
      Future.delayed(const Duration(milliseconds: 900), () { if (!_disposed && token == _token && playing) playFrom(i + 1); });
      return;
    }
    next.addListener(() {
      final v = next!.value;
      if (token == _token && v.isInitialized && !v.isPlaying && v.position >= v.duration && v.duration > Duration.zero) {
        _token++;
        playFrom(i + 1);
      }
    });
    await next.play();
    _preload(i + 1);
  }

  Future<void> _preload(int i) async {
    if (i >= steps.length || _preloadedIndex == i) return;
    _preloaded?.dispose();
    _preloaded = null; _preloadedIndex = -1;
    final controller = await _load(i);
    if (_disposed) { controller?.dispose(); return; }
    _preloaded = controller; _preloadedIndex = controller == null ? -1 : i;
  }

  void replay() { if (steps.isNotEmpty) playFrom(0); }

  void togglePause() {
    if (steps.isEmpty) return;
    if (finished) return replay();
    if (playing) {
      video?.pause(); playing = false;
    } else if (video != null) {
      video!.play(); playing = true;
    } else {
      playFrom(index < 0 ? 0 : index);
      return;
    }
    _notify();
  }

  void stop() {
    _token++;
    video?.pause();
    _preloaded?.dispose(); _preloaded = null; _preloadedIndex = -1;
    playing = false;
    _notify();
  }

  void setSpeed(double value) {
    speed = value;
    video?.setPlaybackSpeed(value);
    _preloaded?.setPlaybackSpeed(value);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _token++;
    video?.dispose();
    _preloaded?.dispose();
    super.dispose();
  }
}

/// The video area for a [SignSequencePlayer]: current word pill on top, tap to pause / continue.
class SignPlayerView extends StatelessWidget {
  final SignSequencePlayer player;
  final String emptyText;
  final String noSignText;
  final IconData emptyIcon;

  const SignPlayerView({super.key, required this.player, required this.emptyText, required this.noSignText, this.emptyIcon = Icons.touch_app_rounded});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const Color blue = Color(0xFF4A7FD0);
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final video = player.video;
        final step = player.currentStep;
        final bool showVideo = video != null && video.value.isInitialized && !player.showMissing;
        return GestureDetector(
          onTap: player.togglePause,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showVideo)
                FittedBox(fit: BoxFit.contain, child: SizedBox(width: video.value.size.width, height: video.value.size.height, child: VideoPlayer(video)))
              else if (step == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FA8EA), blue]).createShader(r),
                          child: Icon(emptyIcon, size: 54, color: Colors.white),
                        ),
                        const SizedBox(height: 14),
                        Text(emptyText, textAlign: TextAlign.center, style: TextStyle(color: c.subText, fontSize: 15, height: 1.4)),
                      ],
                    ),
                  ),
                )
              else if (player.showMissing)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(step.label, style: TextStyle(color: c.text, fontSize: 46, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(noSignText, style: TextStyle(color: c.subText, fontSize: 14)),
                    ],
                  ),
                )
              else
                Center(child: CircularProgressIndicator(color: AppPalette.fg(blue))),
              if (step != null && !player.finished)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(step.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!player.isEmpty && !player.playing)
                Center(
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                    child: Icon(player.finished ? Icons.replay_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

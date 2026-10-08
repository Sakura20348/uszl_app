import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/services/theme_service.dart';

/// Pieces every lesson exercise screen shares (same look as the app's original lesson screens).
const Color lessonBlue = Color(0xFF4A7FD0);
const Color lessonGreen = Color(0xFF22C55E);
const Color lessonRed = Color(0xFFEF4444);

/// Border/radio colour of an answer: blue while picking, then green for right and red for a wrong pick.
Color lessonAccent({required bool selected, required bool? correct}) {
  if (correct == true) return AppPalette.auto(lessonGreen);
  if (correct == false) return AppPalette.auto(lessonRed);
  return selected ? AppPalette.auto(lessonBlue) : AppPalette.auto(Colors.black26);
}

/// The radio circle on answer cards.
class LessonRadio extends StatelessWidget {
  final Color color;
  final bool filled;
  const LessonRadio({super.key, required this.color, required this.filled});

  @override
  Widget build(BuildContext context) => Container(
    height: 22, width: 22,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: filled ? 6 : 2)),
  );
}

// ======================== top bar ========================
/// Close (asks first) · progress "2/20" with the step bar · bookmark (after checking).
class LessonTopBar extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback onClose;
  final VoidCallback? onSave; // null = bookmark disabled
  final bool saved;

  const LessonTopBar({super.key, required this.index, required this.total, required this.onClose, required this.onSave, required this.saved});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onClose,
              child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.close)),
            ),
            GestureDetector(
              onTap: onSave,
              child: Container(
                padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                child: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: onSave != null ? AppPalette.fg(const Color(0xFF42A5F5)) : AppPalette.fg(Colors.grey.shade300)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('${index + 1}/$total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppPalette.fg(Colors.grey[700]!))),
        const SizedBox(height: 4),
        LessonStepBar(current: index, total: total),
      ],
    );
  }
}

/// Segmented progress: the current step is wider and blue. Long lessons are shown as a window of steps.
class LessonStepBar extends StatelessWidget {
  final int current;
  final int total;
  static const int _maxSegments = 10;
  const LessonStepBar({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final int segments = total.clamp(1, _maxSegments);
    // which segment stands for the current exercise
    final int active = total <= _maxSegments ? current : (current * segments / total).floor().clamp(0, segments - 1);
    return Row(
      children: List.generate(segments, (i) {
        final bool isActive = i == active;
        final bool done = i < active;
        return Expanded(
          flex: isActive ? 3 : 2,
          child: Padding(
            padding: EdgeInsets.only(right: i == segments - 1 ? 0 : 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250), height: isActive ? 15 : 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isActive ? 10 : 5), border: Border.all(width: 1, color: AppPalette.border(Colors.blue).withValues(alpha: 0.5)),
                color: isActive ? AppPalette.bg(lessonBlue) : (done ? AppPalette.bg(lessonBlue).withValues(alpha: 0.45) : AppPalette.bg(const Color(0xFFE1F5FE)).withValues(alpha: 0.9)),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ======================== video ========================
/// The sign video (looping, muted) with "Qaytadan", speed and "Burchak" (full screen) under it.
class LessonVideoBox extends StatefulWidget {
  final String? url;
  final double? height;
  final bool showActions;
  const LessonVideoBox({super.key, required this.url, this.height, this.showActions = true});

  @override
  State<LessonVideoBox> createState() => _LessonVideoBoxState();
}

class _LessonVideoBoxState extends State<LessonVideoBox> {
  VideoPlayerController? _controller;
  bool _failed = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    final url = widget.url;
    if (url == null) return;
    // muted sign videos, often several at once: mixWithOthers so they don't take audio focus from each other
    // (Android would pause every other video on the screen)
    final options = VideoPlayerOptions(mixWithOthers: true);
    // a native video view: with the default texture view some phones (Impeller / Vulkan) keep showing
    // only the first frame, especially with several videos on screen
    const view = VideoViewType.platformView;
    final controller = url.startsWith('http')
      ? VideoPlayerController.networkUrl(Uri.parse(url), videoPlayerOptions: options, viewType: view)
      : VideoPlayerController.asset(url, videoPlayerOptions: options, viewType: view);
    _controller = controller;
    controller.initialize().then((_) async {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() {});
      // debug builds: confirm the video really advances (shows in the flutter run log as "SIGN VIDEO")
      if (kDebugMode) {
        Future.delayed(const Duration(seconds: 2), () {
          final v = controller.value;
          debugPrint('SIGN VIDEO ${url.split('/').last}: playing=${v.isPlaying} position=${v.position.inMilliseconds}ms / ${v.duration.inMilliseconds}ms error=${v.errorDescription}');
        });
      }
    }).catchError((Object e) {
      debugPrint('Lesson video not loaded: $e');
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _controller?.setPlaybackSpeed(speed);
  }

  Future<void> _fullScreen() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await Navigator.push(context, PageRouteBuilder(
      opaque: false, barrierColor: Colors.black,
      pageBuilder: (_, _, _) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(child: Stack(children: [
            Center(child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller))),
            Positioned(top: 12, right: 12, child: IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))),
          ])),
        ),
      ),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = _controller;
    final bool ready = controller != null && controller.value.isInitialized;
    // small tiles (no buttons): the video fills exactly the space it is given, like a picture
    final bool tile = !widget.showActions;
    final Widget video = ready
        ? FittedBox(fit: BoxFit.contain, child: SizedBox(width: controller.value.size.width, height: controller.value.size.height, child: VideoPlayer(controller)))
        : Center(child: (_failed || widget.url == null) ? Icon(Icons.videocam_off, color: AppPalette.fg(Colors.grey)) : const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5)));
    // the whole sign stays visible (hands and face); the empty sides take the videos' own light background
    if (tile) return Container(color: const Color(0xFFF0F0F0), child: SizedBox.expand(child: video));
    final double maxHeight = widget.height ?? MediaQuery.of(context).size.height * 0.4;
    // the sign videos are 720×628; until one is loaded the box already has that shape
    final double aspect = ready && controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 720 / 628;
    return Column(
      children: [
        // the box takes the video's own shape, so the video fills it with no empty strips
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: AspectRatio(
            aspectRatio: aspect,
            child: Container(
              decoration: BoxDecoration(color: AppPalette.bg(const Color(0xFFF0F0F0)), borderRadius: BorderRadius.circular(24)), clipBehavior: Clip.antiAlias,
              child: video,
            ),
          ),
        ),
        if (widget.showActions) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: _action(Icons.refresh, loc.translate('again'), ready ? () => controller.seekTo(Duration.zero) : null)),
              const SizedBox(width: 8),
              Expanded(child: _speedButton()),
              const SizedBox(width: 8),
              Expanded(child: _action(Icons.call_made, loc.translate('corner'), ready ? _fullScreen : null)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _action(IconData icon, String text, VoidCallback? onTap) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.8), blurRadius: 12)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: AppPalette.fg(Colors.black54)), const SizedBox(width: 6),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
        ],
      ),
    ),
  );

  Widget _speedButton() => DropdownButtonHideUnderline(
    child: DropdownButton2<double>(
      customButton: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: AppPalette.bg(Colors.white).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.9), blurRadius: 12)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, size: 16, color: AppPalette.fg(Colors.black54)), const SizedBox(width: 6),
            Text('${_speed}x', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.black))),
          ],
        ),
      ),
      items: [0.5, 1.0, 1.5].map((s) {
        final bool on = (_speed - s).abs() < 0.01;
        return DropdownMenuItem<double>(value: s, child: Center(child: Text('${s}x', style: TextStyle(fontSize: 15, fontWeight: on ? FontWeight.bold : FontWeight.normal, color: on ? AppPalette.auto(lessonBlue) : AppPalette.auto(Colors.black87)))));
      }).toList(),
      value: _speed,
      onChanged: (s) { if (s != null) _setSpeed(s); },
      dropdownStyleData: DropdownStyleData(width: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppPalette.bg(Colors.white)), offset: const Offset(0, -8)),
      menuItemStyleData: const MenuItemStyleData(height: 38, padding: EdgeInsets.symmetric(horizontal: 14)),
    ),
  );
}

// ======================== feedback + button ========================
/// Green / red banner shown after checking, above the button.
class LessonFeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  final String? correctAnswer; // shown after a wrong answer
  final String? explanation;
  const LessonFeedbackBanner({super.key, required this.isCorrect, this.correctAnswer, this.explanation});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final Color bg = isCorrect ? AppPalette.auto(const Color(0xFFDCFCE7)) : AppPalette.auto(const Color(0xFFFEE2E2));
    final Color fg = (isCorrect ? AppPalette.auto(const Color(0xFF16A34A)) : AppPalette.auto(const Color(0xFFDC2626))).withValues(alpha: 0.8);
    final Color glow = (isCorrect ? AppPalette.auto(const Color(0xFF16A34A)) : AppPalette.auto(const Color(0xFFDC2626))).withValues(alpha: 0.9);
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: glow, blurRadius: 15)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.translate(isCorrect ? 'answer_correct' : 'answer_wrong'), style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600)),
                if (!isCorrect && correctAnswer?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text('${loc.translate('correct_answer')}: $correctAnswer', style: TextStyle(color: fg, fontSize: 13)),
                ],
                if (explanation?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(explanation!, style: TextStyle(color: fg, fontSize: 13)),
                ],
              ],
            ),
          ),
          Icon(Icons.flag_outlined, color: fg, size: 18),
        ],
      ),
    );
  }
}

/// "Javobni tekshirish" → "Keyingi savol": blue while answering, green / red after checking.
class LessonCheckButton extends StatelessWidget {
  final bool checked;
  final bool? isCorrect;
  final bool canCheck;
  final bool busy;
  final bool last;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  const LessonCheckButton({super.key, required this.checked, required this.isCorrect, required this.canCheck, required this.busy, required this.last, required this.onCheck, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Color bg; Color fg; Color shadow;
    if (!checked) {
      bg = AppPalette.auto(lessonBlue).withValues(alpha: 0.15);
      fg = canCheck ? AppPalette.auto(Colors.blue[900]!) : AppPalette.auto(Colors.blue[700]!);
      shadow = AppPalette.auto(const Color(0xFFBBDEFB)).withValues(alpha: 0.9);
    } else if (isCorrect == true) {
      bg = AppPalette.auto(const Color(0xFF4CAF50)).withValues(alpha: 0.2);
      fg = AppPalette.auto(Colors.white);
      shadow = AppPalette.auto(const Color(0xFF1B5E20)).withValues(alpha: 0.9);
    } else {
      bg = AppPalette.auto(const Color(0xFFF44336)).withValues(alpha: 0.2);
      fg = AppPalette.auto(Colors.white);
      shadow = AppPalette.auto(const Color(0xFFB71C1C)).withValues(alpha: 0.9);
    }
    final String label = !checked ? loc.translate('check_answer_btn') : loc.translate(last ? 'continue' : 'next_question');
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: busy ? null : (checked ? onNext : (canCheck ? onCheck : null)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, disabledBackgroundColor: AppPalette.bg(lessonBlue).withValues(alpha: 0.1), foregroundColor: fg, elevation: 6, shadowColor: shadow,
          side: BorderSide(width: 1, color: AppPalette.border(const Color(0xFF1A237E)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: busy
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppPalette.fg(lessonBlue)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg))),
                  const SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18, color: fg),
                ],
              ),
      ),
    );
  }
}

/// "Darsdan chiqasizmi?" dialog. Returns true when the learner quits.
Future<bool> showQuitLessonDialog(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final quit = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppPalette.border(Colors.white), width: 1)), elevation: 15, backgroundColor: AppPalette.bg(Colors.white).withValues(alpha: 0.7),
      shadowColor: AppPalette.shadow(const Color(0xFF42A5F5)).withValues(alpha: 0.9), title: Text(loc.translate('quit_lesson'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      content: Text(loc.translate('quit_lesson_sub'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.grey[800]!))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(loc.translate('cancel'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.grey[700]!), fontWeight: FontWeight.w600))),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.bg(const Color(0xFFEF9A9A)).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(const Color(0xFFB71C1C)).withValues(alpha: 0.9),
            side: BorderSide(width: 1, color: AppPalette.border(const Color(0xFFB71C1C)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(loc.translate('quit'), style: TextStyle(fontSize: 16, color: AppPalette.fg(Colors.red[900]!), fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return quit == true;
}

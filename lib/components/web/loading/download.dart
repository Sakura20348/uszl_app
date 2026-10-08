import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
class DownloadButton extends StatefulWidget {
  final String status;
  final VoidCallback onTap;

  const DownloadButton({super.key, required this.status, required this.onTap});

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController( vsync: this, duration: const Duration(seconds: 1) ); // like your 1s linear infinite
    if (widget.status == 'downloading') { _controller.repeat(); }
  }

  @override
  void didUpdateWidget(covariant DownloadButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == 'downloading' && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.status != 'downloading' && _controller.isAnimating) { _controller.stop(); _controller.reset(); }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bool isDownloading = widget.status == 'downloading';
    final bool isCompleted = widget.status == 'completed';

    if (isCompleted) {
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withOpacity(0.8), borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppPalette.border(Color(0xFF10B981)), width: 2), boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF10B981)).withOpacity(0.9), blurRadius: 15)]
        ),
        child: Icon(Icons.check_circle, color: AppPalette.fg(Color(0xFF10B981)), size: 24),
      );
    }

    final Color boxColor = isDownloading ? AppPalette.auto(Color(0xFF4A7FD0)).withOpacity(0.8) : AppPalette.auto(Colors.white).withOpacity(0.7);
    final Color iconColor = isDownloading ? AppPalette.auto(Colors.white) : AppPalette.auto(Color(0xFF464646));

    return GestureDetector(
      onTap: isDownloading ? null : widget.onTap, // can't click while downloading
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: boxColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppPalette.border(Colors.white), width: 1),
          boxShadow: [
            BoxShadow(color: isDownloading ? AppPalette.shadow(Colors.black).withOpacity(0.3) : Colors.transparent, blurRadius: 10, offset: Offset(0, isDownloading ? 6: 0)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // sliding arrow
            SizedBox(
              height: 18,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // slide-in-top: y goes -10 -> 0, opacity 0 -> 1
                  final double t = _controller.value;
                  final double dy = isDownloading ? (-10 + 10 * t) : 0;
                  final double op = isDownloading ? t.clamp(0.0, 1.0) : 1.0;
                  return Transform.translate(offset: Offset(0, dy), child: Opacity(opacity: op, child: child));
                },
                child: Icon(Icons.arrow_downward_rounded, color: iconColor, size: 16),
              ),
            ),
            const SizedBox(height: 2),
            // the little "tray" (icon2): bottom + left + right borders
            Container(
              width: 18, height: 5,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: iconColor, width: 2), left: BorderSide(color: iconColor, width: 2), right: BorderSide(color: iconColor, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
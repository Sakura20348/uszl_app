import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';

/// Animated streak flame with the streak count inside.
/// [hot] = streak is alive today: the flame flickers and glows. Otherwise it is a still, grey flame.
class FireStreak extends StatefulWidget {
  final int streak;
  final bool hot;
  final double size;

  const FireStreak({
    super.key,
    required this.streak,
    this.hot = true,
    this.size = 90,
  });

  @override
  State<FireStreak> createState() => _FireStreakState();
}

class _FireStreakState extends State<FireStreak> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this);

  @override
  void initState() {
    super.initState();
    if (widget.hot) _controller.repeat();
  }

  @override
  void didUpdateWidget(FireStreak oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hot && !_controller.isAnimating) _controller.repeat();
    if (!widget.hot && _controller.isAnimating) _controller..stop()..value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;
    final bool hot = widget.hot;

    final List<Color> outer = hot
        ? [AppPalette.bg(const Color(0xFFFFA726)), AppPalette.bg(const Color(0xFFFF5722)), AppPalette.bg(const Color(0xFFD84315))]
        : [AppPalette.bg(const Color(0xFFBDBDBD)), AppPalette.bg(const Color(0xFF9E9E9E)), AppPalette.bg(const Color(0xFF757575))];
    final List<Color> inner = hot
        ? [AppPalette.bg(const Color(0xFFFFF59D)), AppPalette.bg(const Color(0xFFFFCA28)), AppPalette.bg(const Color(0xFFFF9800))]
        : [AppPalette.bg(const Color(0xFFEEEEEE)), AppPalette.bg(const Color(0xFFE0E0E0)), AppPalette.bg(const Color(0xFFBDBDBD))];

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // two out-of-phase waves so the flame breathes and sways instead of just pulsing
          final double t = _controller.value * 2 * math.pi;
          final double breathe = hot ? math.sin(t) : 0;
          final double sway = hot ? math.sin(t * 2 + 1) : 0;

          return SizedBox(
            height: s, width: s,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // ===== 1) glow =====
                if (hot)
                  Positioned(
                    bottom: s * 0.08,
                    child: Container(
                      height: s * 0.62, width: s * 0.62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppPalette.shadow(const Color(0xFFFF6D00)).withValues(alpha: 0.45 + 0.1 * breathe), blurRadius: s * 0.35, spreadRadius: s * 0.04),
                          BoxShadow(color: AppPalette.shadow(const Color(0xFFFFB300)).withValues(alpha: 0.25), blurRadius: s * 0.6, spreadRadius: s * 0.1),
                        ],
                      ),
                    ),
                  ),
                // ===== 2) outer flame =====
                _flame(width: s * 0.8, height: s * (0.96 + 0.03 * breathe), skew: 0.05 * sway, colors: outer),
                // ===== 3) inner flame =====
                Positioned(
                  bottom: s * 0.04,
                  child: _flame(width: s * 0.5, height: s * (0.6 + 0.04 * breathe), skew: -0.07 * sway, colors: inner),
                ),
                // ===== 4) number =====
                Positioned(
                  bottom: s * 0.1,
                  child: SizedBox(
                    width: s * 0.42, height: s * 0.3,
                    child: FittedBox(
                      child: Text(
                        '${widget.streak}',
                        style: TextStyle(
                          fontSize: s * 0.26,
                          fontWeight: FontWeight.w900,
                          color: hot ? AppPalette.fg(const Color(0xFFBF360C)) : AppPalette.fg(Colors.grey.shade700),
                          shadows: [Shadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _flame({required double width, required double height, required double skew, required List<Color> colors}) {
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.skewX(skew),
      child: ClipPath(
        clipper: _FlameClipper(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: width, height: height,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors)),
        ),
      ),
    );
  }
}

// flame silhouette: round belly at the bottom, curling up to one tip with a small lick on the left
class _FlameClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final w = s.width;
    final h = s.height;
    return Path()
      ..moveTo(w * 0.5, h)
      // belly, left half
      ..cubicTo(w * 0.18, h, 0, h * 0.8, 0, h * 0.6)
      // left side up to the small lick
      ..cubicTo(0, h * 0.42, w * 0.1, h * 0.3, w * 0.2, h * 0.22)
      ..quadraticBezierTo(w * 0.22, h * 0.34, w * 0.32, h * 0.4)
      // up to the tip
      ..cubicTo(w * 0.3, h * 0.2, w * 0.46, h * 0.08, w * 0.62, 0)
      // right side down
      ..cubicTo(w * 0.6, h * 0.16, w, h * 0.3, w, h * 0.6)
      // belly, right half
      ..cubicTo(w, h * 0.8, w * 0.82, h, w * 0.5, h)
      ..close();
  }

  @override
  bool shouldReclip(_FlameClipper oldClipper) => false;
}

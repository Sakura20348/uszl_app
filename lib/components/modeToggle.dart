import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:signlang/services/theme_service.dart';

/// Light/dark toggle: a round button whose icon morphs from a looping sun
/// into a crescent moon with twinkling stars (after line-md's sunny/moon icons).
class ModeToggle extends StatefulWidget {
  final double size;
  const ModeToggle({super.key, this.size = 44});

  @override
  State<ModeToggle> createState() => _ModeToggleState();
}

class _ModeToggleState extends State<ModeToggle> with TickerProviderStateMixin {
  late final AnimationController _morph = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 550), value: ThemeService.instance.isDark ? 1 : 0,
  );
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final Animation<double> _t = CurvedAnimation(parent: _morph, curve: Curves.easeInOutCubic);
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    ThemeService.instance.mode.addListener(_sync);
  }

  @override
  void dispose() {
    ThemeService.instance.mode.removeListener(_sync);
    _morph.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _sync() => ThemeService.instance.isDark ? _morph.forward() : _morph.reverse();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final double s = widget.size;

    return Semantics(
      button: true,
      label: 'Toggle theme',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: ThemeService.instance.toggle,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
            scale: _pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: s, height: s,
              decoration: BoxDecoration(color: c.chip, shape: BoxShape.circle, border: Border.all(width: 1, color: c.cardBorder)),
              child: Center(
                child: AnimatedRotation(
                  turns: _pressed ? 20 / 360 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size.square(s / 2),
                      painter: _SunMoonPainter(t: _t, loop: _loop, sunColor: c.accent, moonColor: const Color(0xFFFFD54F)),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ),
    );
  }
}

class _SunMoonPainter extends CustomPainter {
  final Animation<double> t;
  final Animation<double> loop;
  final Color sunColor;
  final Color moonColor;

  _SunMoonPainter({required this.t, required this.loop, required this.sunColor, required this.moonColor}) : super(repaint: Listenable.merge([t, loop]));

  @override
  void paint(Canvas canvas, Size size) {
    // Draw in a 24x24 box like the original SVG icons.
    canvas.scale(size.width / 24, size.height / 24);
    final double p = t.value; // 0 = sun, 1 = moon
    final double spin = loop.value * 2 * math.pi;
    final Color color = Color.lerp(sunColor, moonColor, p)!;
    final fill = Paint()..color = color..isAntiAlias = true;

    // --- Rays: rotate slowly, then shrink into the body on the way to the moon.
    final double rayFade = (1 - p * 1.6).clamp(0.0, 1.0);
    if (rayFade > 0) {
      final ray = Paint()
        ..color = color.withOpacity(rayFade)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final double inner = 7.5, outer = 7.5 + 3 * rayFade;
      final double rotation = spin + p * math.pi / 2;
      for (int i = 0; i < 8; i++) {
        final double a = rotation + i * math.pi / 4;
        final Offset dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(const Offset(12, 12) + dir * inner, const Offset(12, 12) + dir * outer, ray);
      }
    }

    // --- Body: the sun disc grows and a second circle slides in to cut the crescent.
    final double r = 5 + 3.5 * p;
    final Path body = Path()..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: r));
    final Offset cutCenter = Offset.lerp(const Offset(30, -6), const Offset(17, 7), p)!;
    final Path cut = Path()..addOval(Rect.fromCircle(center: cutCenter, radius: r * 0.85));
    canvas.drawPath(Path.combine(PathOperation.difference, body, cut), fill);

    // --- Stars twinkle next to the moon.
    final double starIn = ((p - 0.5) * 2).clamp(0.0, 1.0);
    if (starIn > 0) {
      _star(canvas, const Offset(19.5, 4.5), 2.2 * starIn * (0.75 + 0.25 * math.sin(spin * 6)), color);
      _star(canvas, const Offset(21, 10.5), 1.4 * starIn * (0.75 + 0.25 * math.sin(spin * 6 + 2)), color);
    }
  }

  // Four-point sparkle.
  void _star(Canvas canvas, Offset c, double r, Color color) {
    if (r <= 0) return;
    final double w = r * 0.28;
    final Path star = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(star, Paint()..color = color..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(_SunMoonPainter old) => old.sunColor != sunColor || old.moonColor != moonColor || old.t != t || old.loop != loop;
}

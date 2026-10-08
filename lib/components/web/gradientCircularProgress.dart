import 'dart:math';
import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
class GradientCircularProgress extends StatelessWidget {
  final double progress; // Value between 0.0 and 1.0
  final double size;
  final double strokeWidth;

  const GradientCircularProgress({
    super.key,
    required this.progress,
    this.size = 180.0,
    this.strokeWidth = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GradientCircularPainter(
        progress: progress,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _GradientCircularPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _GradientCircularPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1) Draw the light grey background track ring
    final trackPaint = Paint()
      ..color = AppPalette.auto(Colors.blue).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // 2) Define your beautiful blue gradient profile parameters
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppPalette.bg(Color(0xFF42A5F5)),
          AppPalette.bg(Color(0xFF1E88E5)),
          AppPalette.bg(Color(0xFF1565C0))
        ],
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // Clean rounded indicator edges

    // 3) Draw the active progress line matching the real-time simulation value
    double sweepAngle = 2 * pi * progress;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientCircularPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
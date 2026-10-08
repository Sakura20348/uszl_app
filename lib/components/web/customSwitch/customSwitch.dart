import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
class CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 29,
  });

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400), value: widget.value ? 1.0 : 0.0);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) { widget.value ? _controller.forward() : _controller.reverse(); }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final double trackWidth = 2.2 * s;
    final double trackHeight = s;
    final double knob = 0.8 * s;
    final double pad = 0.1 * s;
    final double travel = trackWidth - knob - 2 * pad;

    return GestureDetector(
      onTap: () {
        if (widget.value) { _controller.reverse(); } else { _controller.forward(); }
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final double t = _animation.value;

          final Gradient trackGradient = LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Color.lerp(AppPalette.bg(Color(0xFFB2EBF2)), AppPalette.bg(Color(0xFF00ACC1)), t)!, Color.lerp(AppPalette.bg(Color(0xFFE0F7FA)), AppPalette.bg(Color(0xFF00838F)), t)!],
          );

          return Container(
            width: trackWidth, height: trackHeight,
            decoration: BoxDecoration(gradient: trackGradient, borderRadius: BorderRadius.circular(trackHeight)),
            child: Stack(
              children: [
                Positioned(
                  left: pad + travel * t, top: pad,
                  child: Container(
                    width: knob, height: knob,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withOpacity(0.30), blurRadius: 7, offset: const Offset(0, 6))],
                      gradient: RadialGradient(center: Alignment(-0.4, -0.5), radius: 0.9, colors: [AppPalette.bg(Colors.white), AppPalette.bg(Color(0xFFDEDEDE))]),
                    ),
                    child: CustomPaint(painter: _FacePainter(t: t)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  /// 0 = sad, 1 = smile
  final double t;
  _FacePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final eyePaint = Paint()
      ..color = AppPalette.auto(Color(0xFF9B9B9B))
      ..style = PaintingStyle.fill;

    // Eyes
    final double eyeR = w * 0.06;
    final double eyeY = h * 0.38;
    canvas.drawCircle(Offset(w * 0.36, eyeY), eyeR, eyePaint);
    canvas.drawCircle(Offset(w * 0.64, eyeY), eyeR, eyePaint);

    // Mouth
    final mouthPaint = Paint()
      ..color = AppPalette.auto(Color(0xFF9B9B9B))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;

    final double left = w * 0.34;
    final double right = w * 0.66;
    final double mouthY = h * 0.65;

    // Control point:
    //  t = 0 (sad):  control ABOVE the line  -> frown  (curves upward)
    //  t = 1 (smile): control BELOW the line -> smile  (curves downward)
    // amp goes from -0.18h (up) to +0.18h (down)
    final double amp = (t - 0.5) * 2 * (h * 0.18);
    final double ctrlY = mouthY + amp;

    final path = Path()
      ..moveTo(left, mouthY)
      ..quadraticBezierTo(w * 0.5, ctrlY, right, mouthY);

    canvas.drawPath(path, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) => old.t != t;
}
import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
class PulseDot extends StatefulWidget {
  final int count;
  const PulseDot({super.key, required this.count});
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30, height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // expanding fading ring (the @keyframes loop)
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final t = _c.value; // 0→1
              return Container(
                width: 10 + t * 30,   // 6px → 30px
                height: 10 + t * 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.bg(Color(0xFF00FF00)).withOpacity((1 - t) * 0.7), // fade out
                ),
              );
            },
          ),
          // solid green dot in the middle
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: AppPalette.bg(Color(0xFF00FF00)).withOpacity(0.2),
              boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF00FF00)).withOpacity(0.9), blurRadius: 15)],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.count > 9 ? '9+' : '${widget.count}',
                style: TextStyle(color: AppPalette.fg(Colors.black), fontSize: 10, fontWeight: FontWeight.w700, height: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
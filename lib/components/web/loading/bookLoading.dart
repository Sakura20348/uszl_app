import 'package:flutter/material.dart';

import 'package:signlang/services/theme_service.dart';
class BookLoader extends StatefulWidget {
  const BookLoader({super.key, this.label = 'Loading'});
  final String label;

  @override
  State<BookLoader> createState() => _BookLoaderState();
}

class _BookLoaderState extends State<BookLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const int _pageCount = 4;          // flipping pages
  static const Duration _duration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 300,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // book body (gradient background)
              Container(
                width: 190,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppPalette.bg(Color(0xFF23C4F8)), AppPalette.bg(Color(0xFF275EFE))],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppPalette.shadow(Color(0xFF275EFE)).withOpacity(0.28), blurRadius: 6, offset: const Offset(0, 4)),
                  ],
                ),
              ),
              // flipping pages
              Positioned(
                left: null,
                child: Transform.translate(
                  offset: const Offset(-46, 0),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: List.generate(_pageCount, (i) => _buildPage(i)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(widget.label, style: TextStyle(color: AppPalette.fg(Color(0xFF6C7486)), fontSize: 15)),
      ],
    );
  }

  Widget _buildPage(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // each page starts its flip at a staggered point in the cycle
        final double start = index * 0.18;          // stagger like nth-child delays
        double t = (_controller.value - start);
        if (t < 0) t += 1.0;                         // wrap around

        // page is visible only during its flip window (~0.5 of the cycle)
        const double flipWindow = 0.55;
        double angle;        // rotation in radians (pi = folded back, 0 = flat)
        double opacity;

        if (t < flipWindow) {
          final double p = t / flipWindow;            // 0..1
          angle = -3.14159 * p;                        // 0 → -pi (flips left, over the spine)
          // fade in at the start, fade out near the end
          if (p < 0.15) {
            opacity = p / 0.15;
          } else if (p > 0.85) {
            opacity = (1 - p) / 0.15;
          } else {
            opacity = 1;
          }
        } else {
          angle = 0;
          opacity = 0;                                 // hidden when not flipping
        }


        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateY(angle),
            child: child,
          ),
        );
      },
      child: Container(
        width: 90,
        height: 120,
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withOpacity(0.55),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
        ),
        // the three lines on each page (like the SVG content)
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (_) => Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppPalette.bg(Colors.white).withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
          ),
        ),
      ),
    );
  }
}
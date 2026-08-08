import 'dart:math';
import 'package:flutter/material.dart';

/// Soft animated saffron blooms — no particle grids or hard line overlays.
class AnimatedAuthBackground extends StatefulWidget {
  final Widget child;
  const AnimatedAuthBackground({super.key, required this.child});

  @override
  State<AnimatedAuthBackground> createState() => _AnimatedAuthBackgroundState();
}

class _AnimatedAuthBackgroundState extends State<AnimatedAuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: Color(0xFFFFFFFF)),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _SoftBloomPainter(_controller.value),
                size: Size.infinite,
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _SoftBloomPainter extends CustomPainter {
  final double t;
  _SoftBloomPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void bloom(Offset c, double radius, Color color) {
      final p = Paint()
        ..shader = RadialGradient(
          colors: [color, Colors.transparent],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);
    }

    bloom(
      Offset(w * (0.92 + 0.02 * sin(t * pi * 2)), h * 0.08),
      w * 0.85,
      const Color(0xFFFF9E4F).withValues(alpha: 0.07),
    );
    bloom(
      Offset(w * 0.08, h * (0.92 + 0.02 * cos(t * pi * 2))),
      w * 0.8,
      const Color(0xFFFF6600).withValues(alpha: 0.05),
    );
    bloom(
      Offset(w * 0.5, h * (0.35 + 0.03 * sin(t * pi * 2 + 1))),
      w * 0.55,
      const Color(0xFFFF9E4F).withValues(alpha: 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant _SoftBloomPainter oldDelegate) =>
      oldDelegate.t != t;
}

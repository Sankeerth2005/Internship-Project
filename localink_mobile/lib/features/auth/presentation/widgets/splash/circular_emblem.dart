import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Layer 6: Circular Emblem (Rotating outer ring with 24 sun rays)
class CircularEmblem extends StatelessWidget {
  final Animation<double> rotationAnimation;
  final double size;

  const CircularEmblem({
    super.key,
    required this.rotationAnimation,
    this.size = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: rotationAnimation.value * 2 * math.pi,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: CircularRingPainter(),
            ),
          ),
        );
      },
    );
  }
}

class CircularRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.40;

    // Main ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, ringPaint);

    // Inner subtle accent ring
    final innerRingPaint = Paint()
      ..color = const Color(0xFFFFC857).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.94, innerRingPaint);

    // Outer subtle accent ring
    final outerRingPaint = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 1.10, outerRingPaint);

    // 24 Sun rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < 24; i++) {
      double angle = (i * 360 / 24) * math.pi / 180;
      Offset p1 = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      Offset p2 = Offset(center.dx + (radius + 6.5) * math.cos(angle), center.dy + (radius + 6.5) * math.sin(angle));
      canvas.drawLine(p1, p2, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

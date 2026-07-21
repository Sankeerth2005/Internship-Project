import 'package:flutter/material.dart';

/// Layer 3: Bottom Sunrise Glow horizon light source
class SunriseGlow extends StatelessWidget {
  final Animation<double> ambientAnimation;

  const SunriseGlow({
    super.key,
    required this.ambientAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientAnimation,
      builder: (context, child) {
        final opacity = ambientAnimation.value;
        return SizedBox.expand(
          child: CustomPaint(
            painter: SunriseGlowPainter(opacity: opacity),
          ),
        );
      },
    );
  }
}

class SunriseGlowPainter extends CustomPainter {
  final double opacity;

  SunriseGlowPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final bottomCenter = Offset(size.width * 0.5, size.height * 0.96);

    // Warm amber/saffron horizon radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.92),
        radius: 0.9,
        colors: [
          const Color(0xFFFFC857).withValues(alpha: 0.7 * opacity),
          const Color(0xFFFF8C00).withValues(alpha: 0.45 * opacity),
          const Color(0xFFD94E00).withValues(alpha: 0.2 * opacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.22, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // Intense central horizon lens flare point
    final flarePointPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          const Color(0xFFFFC857).withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 1.0],
      ).createShader(Rect.fromCircle(center: bottomCenter, radius: 45));

    canvas.drawCircle(bottomCenter, 45, flarePointPaint);
  }

  @override
  bool shouldRepaint(covariant SunriseGlowPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

import 'package:flutter/material.dart';

/// Layer 1: Animated Background Gradient with looping radial ambient pulse
class BackgroundGradient extends StatelessWidget {
  final Animation<double> ambientAnimation;

  const BackgroundGradient({
    super.key,
    required this.ambientAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientAnimation,
      builder: (context, child) {
        final opacity = ambientAnimation.value;
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF090909),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF090909),
                const Color(0xFF100A06),
                Color.lerp(const Color(0xFF2E1002), const Color(0xFF521C04), opacity - 0.4)!,
                Color.lerp(const Color(0xFF8B3200), const Color(0xFFD94E00), opacity - 0.4)!,
              ],
              stops: const [0.0, 0.4, 0.78, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: RadialAmbientGlowPainter(glowOpacity: opacity),
          ),
        );
      },
    );
  }
}

class RadialAmbientGlowPainter extends CustomPainter {
  final double glowOpacity;

  RadialAmbientGlowPainter({required this.glowOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Top-center subtle ambient glow
    final topGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.4),
        radius: 0.8,
        colors: [
          const Color(0xFFFF8C00).withValues(alpha: 0.08 * glowOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), topGlow);
  }

  @override
  bool shouldRepaint(covariant RadialAmbientGlowPainter oldDelegate) {
    return oldDelegate.glowOpacity != glowOpacity;
  }
}

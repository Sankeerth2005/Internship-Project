import 'package:flutter/material.dart';

/// Layer 5/6: Pulsing Glow Behind Circular Emblem (Blur radius 20 -> 45 -> 20)
class GlowBehindLogo extends StatelessWidget {
  final Animation<double> glowPulseAnimation;
  final double size;

  const GlowBehindLogo({
    super.key,
    required this.glowPulseAnimation,
    this.size = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowPulseAnimation,
      builder: (context, child) {
        final blurRadius = glowPulseAnimation.value;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8C00).withValues(alpha: 0.45),
                blurRadius: blurRadius,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: const Color(0xFFFFC857).withValues(alpha: 0.25),
                blurRadius: blurRadius * 0.7,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

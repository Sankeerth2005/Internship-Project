import 'package:flutter/material.dart';

/// Layer 8: Sacred Om Symbol (Pulsing scale 1.0 -> 1.08 -> 1.0, Glow Orange -> Golden -> Orange)
class OmSymbol extends StatelessWidget {
  final Animation<double> omScaleAnimation;
  final Animation<Color?> omGlowColorAnimation;
  final double containerSize;

  const OmSymbol({
    super.key,
    required this.omScaleAnimation,
    required this.omGlowColorAnimation,
    this.containerSize = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([omScaleAnimation, omGlowColorAnimation]),
      builder: (context, child) {
        final scale = omScaleAnimation.value;
        final glowColor = omGlowColorAnimation.value ?? const Color(0xFFFF8C00);

        // Position Om precisely in the center area of the flag cloth
        double centerOffsetX = containerSize * 0.04;
        double centerOffsetY = -containerSize * 0.16;

        return Transform.translate(
          offset: Offset(centerOffsetX, centerOffsetY),
          child: Transform.scale(
            scale: scale,
            child: Text(
              'ॐ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF000000),
                shadows: [
                  Shadow(
                    color: glowColor.withValues(alpha: 0.9),
                    blurRadius: 10,
                  ),
                  Shadow(
                    color: glowColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

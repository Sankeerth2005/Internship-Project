import 'package:flutter/material.dart';
import 'glow_behind_logo.dart';
import 'circular_emblem.dart';
import 'waving_flag.dart';
import 'om_symbol.dart';

/// Modular Animated Logo Widget combining layers 6, 7, 8 & glow
class AnimatedLogo extends StatelessWidget {
  final Animation<double> logoScaleAnimation;
  final Animation<double> ringRotationAnimation;
  final Animation<double> glowPulseAnimation;
  final Animation<double> flagWaveAnimation;
  final Animation<double> omScaleAnimation;
  final Animation<Color?> omGlowColorAnimation;
  final double size;

  const AnimatedLogo({
    super.key,
    required this.logoScaleAnimation,
    required this.ringRotationAnimation,
    required this.glowPulseAnimation,
    required this.flagWaveAnimation,
    required this.omScaleAnimation,
    required this.omGlowColorAnimation,
    this.size = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'app_logo_emblem_hero',
      child: AnimatedBuilder(
        animation: logoScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: logoScaleAnimation.value,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow Layer
                  GlowBehindLogo(
                    glowPulseAnimation: glowPulseAnimation,
                    size: size,
                  ),
                  // Circular Emblem Ring Layer
                  CircularEmblem(
                    rotationAnimation: ringRotationAnimation,
                    size: size,
                  ),
                  // Waving Saffron Flag Layer
                  WavingFlag(
                    flagWaveAnimation: flagWaveAnimation,
                    size: size,
                  ),
                  // Sacred Om Symbol Layer
                  OmSymbol(
                    omScaleAnimation: omScaleAnimation,
                    omGlowColorAnimation: omGlowColorAnimation,
                    containerSize: size,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

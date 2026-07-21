import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Layer 5: Floating Glowing Particles (25-30 slow rising ambient sparks)
class FloatingParticles extends StatelessWidget {
  final Animation<double> particleAnimation;

  const FloatingParticles({
    super.key,
    required this.particleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: particleAnimation,
      builder: (context, child) {
        return SizedBox.expand(
          child: CustomPaint(
            painter: ParticlePainter(progress: particleAnimation.value),
          ),
        );
      },
    );
  }
}

class ParticleSpec {
  final double xPct;
  final double speed;
  final double size;
  final double opacity;
  final double swayFreq;

  const ParticleSpec({
    required this.xPct,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.swayFreq,
  });
}

class ParticlePainter extends CustomPainter {
  final double progress;

  static final List<ParticleSpec> _particles = List.generate(28, (i) {
    final rand = math.Random(i * 9973);
    return ParticleSpec(
      xPct: rand.nextDouble(),
      speed: 0.3 + rand.nextDouble() * 0.7,
      size: 1.2 + rand.nextDouble() * 2.5,
      opacity: 0.25 + rand.nextDouble() * 0.65,
      swayFreq: 1.0 + rand.nextDouble() * 2.5,
    );
  });

  ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      double yVal = (1.0 - ((progress * p.speed + (i / _particles.length)) % 1.0)) * h;
      double xVal = (p.xPct * w) + math.sin((progress * p.swayFreq + i) * math.pi) * 12.0;

      final paint = Paint()
        ..color = Color.lerp(const Color(0xFFFF8C00), const Color(0xFFFFC857), (i % 3) / 2.0)!
            .withValues(alpha: p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(xVal, yVal), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

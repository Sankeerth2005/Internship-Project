import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Layer 4: Animated Decorative Energy Waves (Slow horizontal sine wave lines)
class EnergyWaves extends StatelessWidget {
  final Animation<double> waveAnimation;

  const EnergyWaves({
    super.key,
    required this.waveAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveAnimation,
      builder: (context, child) {
        return SizedBox.expand(
          child: CustomPaint(
            painter: EnergyWavePainter(wavePhase: waveAnimation.value),
          ),
        );
      },
    );
  }
}

class EnergyWavePainter extends CustomPainter {
  final double wavePhase;

  EnergyWavePainter({required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseY = h * 0.94;

    // Horizontal offset 5px (Left -> Right -> Left)
    final horizontalShift = math.sin(wavePhase * 2 * math.pi) * 5.0;

    final wavePaint1 = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final wavePaint2 = Paint()
      ..color = const Color(0xFFFFC857).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final wavePaint3 = Paint()
      ..color = const Color(0xFFFF5500).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    _drawSineWave(canvas, wavePaint1, w, baseY - 10, amplitude: 18, wavelength: w * 0.75, shift: horizontalShift);
    _drawSineWave(canvas, wavePaint2, w, baseY, amplitude: 24, wavelength: w * 0.60, shift: -horizontalShift * 1.2);
    _drawSineWave(canvas, wavePaint3, w, baseY + 10, amplitude: 14, wavelength: w * 0.85, shift: horizontalShift * 0.8);
  }

  void _drawSineWave(Canvas canvas, Paint paint, double width, double baseY, {required double amplitude, required double wavelength, required double shift}) {
    final path = Path();
    path.moveTo(0, baseY + math.sin((shift / wavelength) * 2 * math.pi) * amplitude);

    for (double x = 0; x <= width; x += 3.0) {
      double y = baseY + math.sin(((x + shift) / wavelength) * 2 * math.pi) * amplitude;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EnergyWavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase;
  }
}

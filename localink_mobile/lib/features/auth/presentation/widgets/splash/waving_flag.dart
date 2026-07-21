import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Layer 7: Saffron Flag (Fixed pole, waving triangular cloth cloth)
class WavingFlag extends StatelessWidget {
  final Animation<double> flagWaveAnimation;
  final double size;

  const WavingFlag({
    super.key,
    required this.flagWaveAnimation,
    this.size = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: flagWaveAnimation,
        builder: (context, child) {
          final waveAngle = flagWaveAnimation.value * (math.pi / 180.0);
          return CustomPaint(
            painter: FlagPainter(waveAngle: waveAngle),
          );
        },
      ),
    );
  }
}

class FlagPainter extends CustomPainter {
  final double waveAngle;

  FlagPainter({required this.waveAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.40;

    double poleX = center.dx - 10;
    double topY = center.dy - radius + 12;
    double bottomY = center.dy + radius - 12;

    // 1. Fixed Flag Pole
    final polePaint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(poleX, topY), Offset(poleX, bottomY), polePaint);

    final poleHighlight = Paint()
      ..color = const Color(0xFFFF8C00)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(poleX - 1.2, topY), Offset(poleX - 1.2, bottomY), poleHighlight);

    // 2. Waving Triangular Flag Cloth
    double clothTopY = center.dy - radius + 16;
    double clothBottomY = center.dy + 8;
    double tipX = center.dx + radius - 8;

    final flagPath = Path();
    flagPath.moveTo(poleX, clothTopY);

    // Top edge with subtle wave
    double waveOffsetTop = math.sin(waveAngle * 3) * 4.0;
    double midX = (poleX + tipX) / 2;
    double midY = (clothTopY + (clothTopY + clothBottomY) / 2) / 2 + waveOffsetTop;

    flagPath.quadraticBezierTo(midX, midY, tipX + math.cos(waveAngle) * 3, (clothTopY + clothBottomY) / 2 + waveOffsetTop);

    // Bottom edge with subtle wave
    double waveOffsetBottom = math.cos(waveAngle * 3) * 3.0;
    flagPath.quadraticBezierTo(midX, clothBottomY + waveOffsetBottom, poleX, clothBottomY);
    flagPath.close();

    final flagPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFFFF8C00), Color(0xFFFF5500)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTRB(poleX, clothTopY, tipX, clothBottomY));

    canvas.drawPath(flagPath, flagPaint);

    // Subtle cloth shadow fold
    final foldPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(flagPath, foldPaint);
  }

  @override
  bool shouldRepaint(covariant FlagPainter oldDelegate) {
    return oldDelegate.waveAngle != waveAngle;
  }
}

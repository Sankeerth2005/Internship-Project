import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget? child;
  final bool showCenterWarmth;

  const AppBackground({
    super.key,
    this.child,
    this.showCenterWarmth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _BackgroundGlowPainter(showCenterWarmth: showCenterWarmth),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _BackgroundGlowPainter extends CustomPainter {
  final bool showCenterWarmth;

  _BackgroundGlowPainter({required this.showCenterWarmth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // White base
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));

    // Top-right Saffron Bloom
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF9E4F).withValues(alpha: 0.055),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width, 0),
            radius: size.width * 0.9,
          ),
        ),
    );

    // Bottom-left Orange Bloom
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF6600).withValues(alpha: 0.038),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(0, size.height),
            radius: size.width * 0.85,
          ),
        ),
    );

    // Center subtle warmth (if enabled, e.g. for login/otp screens)
    if (showCenterWarmth) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFF9E4F).withValues(alpha: 0.022),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height * 0.38),
              radius: size.width * 0.55,
            ),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundGlowPainter old) =>
      old.showCenterWarmth != showCenterWarmth;
}

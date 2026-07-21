import 'package:flutter/material.dart';

/// Layer 2: Temple Silhouette Background with vector shikhara spires
class TempleBackground extends StatelessWidget {
  final Animation<double> templeOpacityAnimation;

  const TempleBackground({
    super.key,
    required this.templeOpacityAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: templeOpacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: templeOpacityAnimation.value * 0.35,
          child: SizedBox.expand(
            child: CustomPaint(
              painter: TempleSilhouettePainter(),
            ),
          ),
        );
      },
    );
  }
}

class TempleSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final silPaint = Paint()
      ..color = const Color(0xFF090909)
      ..style = PaintingStyle.fill;

    double bottomY = size.height;
    double w = size.width;

    // Base ground terrain curve
    final pathGround = Path();
    pathGround.moveTo(0, bottomY);
    pathGround.lineTo(0, bottomY - 14);
    pathGround.quadraticBezierTo(w * 0.25, bottomY - 8, w * 0.5, bottomY - 12);
    pathGround.quadraticBezierTo(w * 0.75, bottomY - 18, w, bottomY - 10);
    pathGround.lineTo(w, bottomY);
    canvas.drawPath(pathGround, silPaint);

    // Far background mini spires
    _drawShikhara(canvas, silPaint, w * 0.12, bottomY, w * 0.12, size.height * 0.20);
    _drawShikhara(canvas, silPaint, w * 0.26, bottomY, w * 0.15, size.height * 0.26);
    _drawShikhara(canvas, silPaint, w * 0.40, bottomY, w * 0.11, size.height * 0.18);
    _drawShikhara(canvas, silPaint, w * 0.60, bottomY, w * 0.13, size.height * 0.22);
    _drawShikhara(canvas, silPaint, w * 0.88, bottomY, w * 0.14, size.height * 0.24);

    // Foreground detailed shikhara spires (matching user's artwork layout)
    _drawShikhara(canvas, silPaint, w * 0.08, bottomY, w * 0.20, size.height * 0.34);
    _drawShikhara(canvas, silPaint, w * 0.22, bottomY, w * 0.24, size.height * 0.42);
    _drawShikhara(canvas, silPaint, w * 0.38, bottomY, w * 0.18, size.height * 0.30);
    _drawShikhara(canvas, silPaint, w * 0.64, bottomY, w * 0.22, size.height * 0.36);
    _drawShikhara(canvas, silPaint, w * 0.82, bottomY, w * 0.26, size.height * 0.44);
    _drawShikhara(canvas, silPaint, w * 0.95, bottomY, w * 0.16, size.height * 0.28);
  }

  void _drawShikhara(Canvas canvas, Paint paint, double centerX, double bottomY, double width, double height) {
    final path = Path();
    double topY = bottomY - height;
    double halfW = width / 2;
    path.moveTo(centerX - halfW, bottomY);
    int tiers = 8;
    for (int i = 0; i < tiers; i++) {
      double pct = i / tiers;
      double nextPct = (i + 1) / tiers;
      double curW = halfW * (1.0 - pct * 0.85);
      double curY = bottomY - (height * pct);
      double nextY = bottomY - (height * nextPct);
      path.lineTo(centerX - curW, curY);
      path.lineTo(centerX - curW, nextY);
    }
    // Kalasha spire pinnacle
    path.lineTo(centerX - 2, topY - 6);
    path.lineTo(centerX, topY - 10);
    path.lineTo(centerX + 2, topY - 6);
    for (int i = tiers - 1; i >= 0; i--) {
      double pct = i / tiers;
      double nextPct = (i + 1) / tiers;
      double curW = halfW * (1.0 - pct * 0.85);
      double curY = bottomY - (height * pct);
      double nextY = bottomY - (height * nextPct);
      path.lineTo(centerX + curW, nextY);
      path.lineTo(centerX + curW, curY);
    }
    path.lineTo(centerX + halfW, bottomY);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

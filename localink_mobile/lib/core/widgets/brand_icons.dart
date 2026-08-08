import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Brand imagery — prefer PNGs in assets/images/.
class BrandIcons {
  BrandIcons._();

  static const omAsset = 'assets/images/om_symbol.png';
  static const googleAsset = 'assets/images/google_g.png';
  static const splashAsset = 'assets/images/splash_screen.png';
  static const splashLogoAsset = 'assets/images/splash_logo.png';

  /// Om mark from asset (transparent PNG). Optional tint via [color].
  static Widget om({double size = 56, Color? color}) {
    final image = Image.asset(
      omAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, error, stackTrace) => Text(
        'ॐ',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? AppTheme.accentColor,
          fontSize: size * 0.92,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );

    if (color == null) return image;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: image,
    );
  }

  /// Compact circular brand chip for headers / nav.
  static Widget omChip({double size = 28}) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primarySolarGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        padding: EdgeInsets.all(size * 0.12),
        child: om(size: size * 0.55),
      ),
    );
  }

  /// Official-style Google G: use asset when provided, else painted logo.
  static Widget google({double size = 24}) {
    return Image.asset(
      googleAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, error, stackTrace) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: GoogleGPainter()),
      ),
    );
  }
}

/// Accurate multicolor Google "G" for fallback when asset is missing.
class GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = s * 0.42;
    final stroke = s * 0.18;
    final rect = Rect.fromCircle(center: c, radius: r);

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final red = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final yellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final green = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawArc(rect, -0.4, 1.6, false, blue);
    canvas.drawArc(rect, 1.2, 1.1, false, green);
    canvas.drawArc(rect, 2.3, 0.9, false, yellow);
    canvas.drawArc(rect, 3.2, 1.1, false, red);

    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(c.dx - stroke * 0.1, c.dy - stroke / 2, r + stroke * 0.35, stroke),
        const Radius.circular(1),
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

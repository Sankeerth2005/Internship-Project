import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        context.go('/welcome');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: SplashBackgroundPainter(),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated Emblem and Title block
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sun/Flag custom painted logo emblem
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: SplashEmblemPainter(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Title text
                    const Text(
                      'VOCAL FOR SANATAN',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    // Subtitle
                    Text(
                      'Discover & Support Local Heritage',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw vertical gradient background
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0C0C0C), // Deep charcoal black at the top
          const Color(0xFF0F0F0F),
          const Color(0xFF5E1B00), // Dark brown/orange merge in mid-lower
          const Color(0xFFB33600), // Saffron sunset orange at the bottom
        ],
        stops: const [0.0, 0.4, 0.8, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // 2. Draw vertical pinstripes
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    double spacing = 12.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stripePaint);
    }

    // 3. Bottom left & bottom right glowing circles
    final glowPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF5500).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(0, size.height), radius: size.width * 0.5));
    canvas.drawCircle(Offset(0, size.height), size.width * 0.5, glowPaint1);

    final glowPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF7A00).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: size.width * 0.4));
    canvas.drawCircle(Offset(size.width, size.height), size.width * 0.4, glowPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SplashEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    final paint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, paint);

    // 24 rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (int i = 0; i < 24; i++) {
      double angle = (i * 360 / 24) * 3.14159 / 180;
      Offset p1 = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      Offset p2 = Offset(center.dx + (radius + 5) * math.cos(angle), center.dy + (radius + 5) * math.sin(angle));
      canvas.drawLine(p1, p2, rayPaint);
    }

    // Draw flag (Dhwaja) inside
    final flagPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.fill;

    final flagPath = Path();
    double poleX = center.dx - 6;
    flagPath.moveTo(poleX, center.dy - radius + 8);
    flagPath.lineTo(poleX, center.dy + radius - 8);

    // Flag cloth (triangular)
    flagPath.moveTo(poleX, center.dy - radius + 11);
    flagPath.lineTo(center.dx + radius - 6, center.dy - 3);
    flagPath.lineTo(poleX, center.dy + 5);
    flagPath.close();

    canvas.drawPath(flagPath, flagPaint);

    // Draw a dark pole line to separate
    final poleLinePaint = Paint()
      ..color = const Color(0xFF0C0C0C)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(poleX, center.dy - radius + 8), Offset(poleX, center.dy + radius - 8), poleLinePaint);

    // Draw a Om symbol text in black on the flag
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ॐ',
        style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(poleX + 5, center.dy - radius + 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

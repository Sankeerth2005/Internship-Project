import 'dart:math';
import 'package:flutter/material.dart';

/// Animated background matching the Angular website's plasma/particle effects.
class AnimatedAuthBackground extends StatefulWidget {
  final Widget child;
  const AnimatedAuthBackground({super.key, required this.child});

  @override
  State<AnimatedAuthBackground> createState() => _AnimatedAuthBackgroundState();
}

class _AnimatedAuthBackgroundState extends State<AnimatedAuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Positioned.fill(
          child: Container(color: const Color(0xFF050505)),
        ),

        // Plasma glow effect
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return CustomPaint(painter: _PlasmaPainter(t), size: Size.infinite);
            },
          ),
        ),

        // Particle dot grid
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(_controller.value),
                size: Size.infinite,
              );
            },
          ),
        ),

        // Radial gradient overlay (right side glow)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.4, -0.4),
                radius: 1.2,
                colors: [
                  Color(0x26C8A97E), // rgba(200,169,126,0.15)
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content on top
        widget.child,
      ],
    );
  }
}

/// Draws animated plasma-style radial gradients.
class _PlasmaPainter extends CustomPainter {
  final double t;
  _PlasmaPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gradient 1: circle at ~30% 40%
    final c1 = Offset(
      w * (0.3 + 0.05 * sin(t * pi * 2)),
      h * (0.4 + 0.04 * cos(t * pi * 2)),
    );
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x40C8A97E), // rgba(200,169,126,0.25)
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c1, radius: w * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p1);

    // Gradient 2: circle at ~70% 30%
    final c2 = Offset(
      w * (0.7 - 0.04 * cos(t * pi * 2)),
      h * (0.3 + 0.05 * sin(t * pi * 2)),
    );
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x2EFFD7A0), // rgba(255,215,160,0.18)
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c2, radius: w * 0.45));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p2);

    // Gradient 3: circle at ~50% 80%
    final c3 = Offset(
      w * (0.5 + 0.03 * sin(t * pi * 2 + 1)),
      h * (0.8 - 0.04 * cos(t * pi * 2 + 1)),
    );
    final p3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x26C8A97E), // rgba(200,169,126,0.15)
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c3, radius: w * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p3);
  }

  @override
  bool shouldRepaint(covariant _PlasmaPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Draws a drifting gold particle dot grid.
class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 70.0;
    const radius = 1.2;
    final paint = Paint()..color = const Color(0x40C8A97E); // opacity ~0.25
    final drift =
        t * 300; // particles move up by 300px over the animation cycle

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = -300; y < size.height + 300; y += spacing) {
        final dy = (y - drift) % (size.height + 300);
        if (dy >= 0 && dy <= size.height) {
          canvas.drawCircle(Offset(x, dy), radius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}

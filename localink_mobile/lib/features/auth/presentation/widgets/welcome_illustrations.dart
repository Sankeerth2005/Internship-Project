import 'package:flutter/material.dart';

class DiscoveryIllustration extends StatelessWidget {
  const DiscoveryIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _DiscoveryPainter(),
    );
  }
}

class _DiscoveryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Ambient circle
    canvas.drawCircle(
      center,
      w * 0.44,
      Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );

    // Concentric rings
    final ringPaint = Paint()
      ..color = const Color(0xFFFF9E4F).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, w * 0.30, ringPaint);
    canvas.drawCircle(center, w * 0.42, ringPaint..color = const Color(0xFFFF9E4F).withValues(alpha: 0.09));

    // Connecting lines
    final linePaint = Paint()
      ..color = const Color(0xFFEAE8E3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final pins = [
      Offset(w * 0.2, h * 0.32),
      Offset(w * 0.8, h * 0.28),
      Offset(w * 0.32, h * 0.76),
      Offset(w * 0.72, h * 0.72),
    ];
    for (final pin in pins) {
      canvas.drawLine(center, pin, linePaint);
    }

    // Central badge
    canvas.drawCircle(center, 26, Paint()..color = const Color(0xFFFF6600));
    canvas.drawCircle(center, 22, Paint()..color = Colors.white);

    // Search icon
    final searchPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(w / 2 - 2, h / 2 - 2), 6, searchPaint);
    canvas.drawLine(Offset(w / 2 + 2.5, h / 2 + 2.5), Offset(w / 2 + 9, h / 2 + 9), searchPaint);

    // Outer pins
    for (int i = 0; i < pins.length; i++) {
      final color = i.isEven ? const Color(0xFFFF6600) : const Color(0xFFFF9E4F);
      canvas.drawCircle(pins[i], 11, Paint()..color = color);
      canvas.drawCircle(pins[i], 4.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class DirectCommunicationIllustration extends StatelessWidget {
  const DirectCommunicationIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _DirectCommunicationPainter(),
    );
  }
}

class _DirectCommunicationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background bloom
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.44,
      Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    // Two device cards
    final cardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFFEAE8E3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cardRects = [
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.2, w * 0.32, h * 0.56), const Radius.circular(18)),
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.60, h * 0.2, w * 0.32, h * 0.56), const Radius.circular(18)),
    ];

    for (final r in cardRects) {
      canvas.drawRRect(r, Paint()..color = Colors.black.withValues(alpha: 0.025)..style = PaintingStyle.fill);
      canvas.drawRRect(r.shift(const Offset(0, -2)), cardPaint);
      canvas.drawRRect(r.shift(const Offset(0, -2)), borderPaint);
    }

    // Avatar circles
    canvas.drawCircle(Offset(w * 0.24, h * 0.48), 18, Paint()..color = const Color(0xFFFF6600));
    canvas.drawCircle(Offset(w * 0.24, h * 0.48), 7, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.76, h * 0.48), 18, Paint()..color = const Color(0xFFFF9E4F));
    canvas.drawCircle(Offset(w * 0.76, h * 0.48), 7, Paint()..color = Colors.white);

    // Curved bridge line
    final path = Path()
      ..moveTo(w * 0.24 + 18, h * 0.48)
      ..cubicTo(w * 0.42, h * 0.36, w * 0.58, h * 0.36, w * 0.76 - 18, h * 0.48);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF6600)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Arrow
    final arrow = Path()
      ..moveTo(w * 0.76 - 20, h * 0.48)
      ..lineTo(w * 0.76 - 28, h * 0.41)
      ..lineTo(w * 0.76 - 24, h * 0.50)
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFFFF6600));

    // Zero badge
    final badgePaint = Paint()..color = const Color(0xFF1E824C);
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), 14, badgePaint);
    final textSpan = TextSpan(
      text: '0%',
      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(w * 0.5 - tp.width / 2, h * 0.32 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class AiAssistantIllustration extends StatelessWidget {
  const AiAssistantIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _AiAssistantPainter(),
    );
  }
}

class _AiAssistantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.44,
      Paint()
        ..color = const Color(0xFFFF9E4F).withValues(alpha: 0.055)
        ..style = PaintingStyle.fill,
    );

    // AI speech bubble (orange)
    final bubble1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.55, h * 0.22),
      const Radius.circular(14),
    );
    canvas.drawRRect(bubble1, Paint()..color = const Color(0xFFFF6600));

    // Tail for AI bubble
    final tail1 = Path()
      ..moveTo(w * 0.18, h * 0.42)
      ..lineTo(w * 0.14, h * 0.52)
      ..lineTo(w * 0.28, h * 0.42)
      ..close();
    canvas.drawPath(tail1, Paint()..color = const Color(0xFFFF6600));

    // Dots inside AI bubble
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * 0.26 + i * w * 0.10, h * 0.31),
        3.5,
        Paint()..color = Colors.white,
      );
    }

    // User speech bubble
    final bubble2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.52, w * 0.55, h * 0.22),
      const Radius.circular(14),
    );
    canvas.drawRRect(bubble2, Paint()..color = const Color(0xFFF9F8F6));
    canvas.drawRRect(
      bubble2,
      Paint()
        ..color = const Color(0xFFEAE8E3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final tail2 = Path()
      ..moveTo(w * 0.82, h * 0.74)
      ..lineTo(w * 0.86, h * 0.82)
      ..lineTo(w * 0.74, h * 0.74)
      ..close();
    canvas.drawPath(tail2, Paint()..color = const Color(0xFFF9F8F6));

    // Mic icon in user bubble
    canvas.drawCircle(
      Offset(w * 0.625, h * 0.63),
      5,
      Paint()..color = const Color(0xFFFF9E4F),
    );

    // Sparkle dots
    final sparklePaint = Paint()..color = const Color(0xFFFF6600).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(w * 0.82, h * 0.2), 4, sparklePaint);
    canvas.drawCircle(Offset(w * 0.87, h * 0.28), 2.5, sparklePaint..color = const Color(0xFFFF9E4F).withValues(alpha: 0.5));
    canvas.drawCircle(Offset(w * 0.79, h * 0.14), 2, sparklePaint..color = const Color(0xFFFF6600).withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class CommunitySupportIllustration extends StatelessWidget {
  const CommunitySupportIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _CommunitySupportPainter(),
    );
  }
}

class _CommunitySupportPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    canvas.drawCircle(
      center,
      w * 0.44,
      Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    // Outer connection rings
    final wavePaint = Paint()
      ..color = const Color(0xFFFF9E4F).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 60, wavePaint);
    canvas.drawCircle(center, 78, wavePaint..color = const Color(0xFFFF9E4F).withValues(alpha: 0.1));

    // Central verified shield
    canvas.drawCircle(center, 36, Paint()..color = const Color(0xFFFF6600));
    canvas.drawCircle(center, 30, Paint()..color = Colors.white);

    // Check mark
    final check = Path()
      ..moveTo(w / 2 - 11, h / 2 - 1)
      ..lineTo(w / 2 - 2, h / 2 + 8)
      ..lineTo(w / 2 + 13, h / 2 - 8);
    canvas.drawPath(
      check,
      Paint()
        ..color = const Color(0xFFFF6600)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Community nodes
    final nodes = [
      Offset(w * 0.22, h * 0.28),
      Offset(w * 0.78, h * 0.28),
      Offset(w * 0.16, h * 0.68),
      Offset(w * 0.84, h * 0.68),
    ];

    for (final node in nodes) {
      canvas.drawLine(
        center,
        node,
        Paint()
          ..color = const Color(0xFFFF9E4F).withValues(alpha: 0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(node, 13, Paint()..color = const Color(0xFFFF9E4F));
      canvas.drawCircle(node, 5.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

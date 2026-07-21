import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  final List<Particle> _particles = List.generate(35, (index) => Particle());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _verifyOtp() {
    final otp = _otpCode;
    if (otp.length != 6 || int.tryParse(otp) == null) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP code.'),
          backgroundColor: Color(0xFFFF4D4F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      context.push('/reset-password', extra: {
        'email': widget.email,
        'otp': otp,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070605),
      body: Stack(
        children: [
          // ─── 1. TOP HERO ARTWORK CANVAS ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: CustomPaint(
              painter: VerifyHeroPainter(_particles),
            ),
          ),

          // ─── 2. MAIN SCROLLABLE BODY ───
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0F0C0A).withValues(alpha: 0.7),
                          border: Border.all(
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: Color(0xFFFF9D00),
                        ),
                      ),
                    ),
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80), // Clearance for hero header emblem

                          // Title: "Verify OTP"
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Verify ',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: 'OTP',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF8C00),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Lotus Divider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 1.2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFFFF9D00).withValues(alpha: 0.6),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Icon(
                                  Icons.filter_vintage_rounded,
                                  size: 14,
                                  color: Color(0xFFFF9D00),
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 1.2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF9D00).withValues(alpha: 0.6),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Subtitle Text with REAL Email Data
                          const Text(
                            'We have sent a 6-digit OTP to',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              color: Color(0xFFCDC3B8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.email.isNotEmpty ? widget.email : 'your email address',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF8C00),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // ─── 3. MAIN CARD CONTAINER ───
                          Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 26.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0C0A),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Top Circle Icon
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1A140E),
                                      border: Border.all(
                                        color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.mail_outline_rounded,
                                      color: Color(0xFFFF9D00),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  const Text(
                                    'Enter 6-Digit OTP',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Please enter the OTP sent to your email address',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.5,
                                      color: Color(0xFFA59B90),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 22),

                                  // ─── 6 PIN INPUT BOXES ───
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: List.generate(6, (index) {
                                      final isFilled = _controllers[index].text.isNotEmpty;
                                      final isFocused = _focusNodes[index].hasFocus;

                                      return SizedBox(
                                        width: 44,
                                        height: 54,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF14110E),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isFocused || isFilled
                                                  ? const Color(0xFFFF7A00)
                                                  : const Color(0xFF2E241A),
                                              width: isFocused || isFilled ? 1.6 : 1.0,
                                            ),
                                            boxShadow: isFocused
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                                                      blurRadius: 8,
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Center(
                                            child: TextFormField(
                                              controller: _controllers[index],
                                              focusNode: _focusNodes[index],
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              maxLength: 1,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                              decoration: const InputDecoration(
                                                counterText: '',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              onChanged: (value) {
                                                if (value.isNotEmpty) {
                                                  if (index < 5) {
                                                    _focusNodes[index + 1].requestFocus();
                                                  } else {
                                                    _focusNodes[index].unfocus();
                                                  }
                                                } else {
                                                  if (index > 0) {
                                                    _focusNodes[index - 1].requestFocus();
                                                  }
                                                }
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 22),

                                  // Security Info Box
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16110D),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFFF7A00).withValues(alpha: 0.18),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.verified_user_outlined,
                                          color: Color(0xFFFF9D00),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'This OTP is valid for a single use only.\nDo not share it with anyone.',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11.5,
                                              color: Color(0xFFA59B90),
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Action Button: "Verify OTP"
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF8000),
                                            Color(0xFFD63E00),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF6A00).withValues(alpha: 0.4),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _verifyOtp,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Spacer(),
                                                  const Text(
                                                    'Verify OTP',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.4,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Color(0xFFFF9E1B),
                                                    ),
                                                    child: const Icon(
                                                      Icons.arrow_forward_rounded,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double opacity;

  Particle() {
    final rand = math.Random();
    x = rand.nextDouble();
    y = rand.nextDouble();
    opacity = 0.15 + rand.nextDouble() * 0.55;
  }
}

class VerifyHeroPainter extends CustomPainter {
  final List<Particle> particles;

  VerifyHeroPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final sunPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 0.85,
        colors: [
          const Color(0xFFFF6A00).withValues(alpha: 0.35),
          const Color(0xFF2A0D00).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawRect(rect, sunPaint);

    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      particlePaint.color = const Color(0xFFFF9D00).withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        2.0,
        particlePaint,
      );
    }

    final wavePaint = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(size.width * 0.3, size.height * 0.3, size.width * 0.7, size.height * 0.7, size.width, size.height * 0.4);

    canvas.drawPath(path1, wavePaint);

    final templePaint = Paint()
      ..color = const Color(0xFF140D08)
      ..style = PaintingStyle.fill;

    final templePath = Path();
    templePath.moveTo(0, size.height);
    templePath.lineTo(size.width * 0.1, size.height * 0.65);
    templePath.lineTo(size.width * 0.18, size.height * 0.55);
    templePath.lineTo(size.width * 0.25, size.height * 0.65);
    templePath.lineTo(size.width * 0.35, size.height * 0.45);
    templePath.lineTo(size.width * 0.5, size.height * 0.2);
    templePath.lineTo(size.width * 0.65, size.height * 0.45);
    templePath.lineTo(size.width * 0.75, size.height * 0.65);
    templePath.lineTo(size.width * 0.82, size.height * 0.55);
    templePath.lineTo(size.width * 0.9, size.height * 0.65);
    templePath.lineTo(size.width, size.height);
    templePath.close();

    canvas.drawPath(templePath, templePaint);

    final centerX = size.width * 0.5;
    final centerY = size.height * 0.48;

    final gearPaint = Paint()
      ..color = const Color(0xFFFF9D00).withValues(alpha: 0.9)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(centerX, centerY), 32, gearPaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final angle = (i * 20) * math.pi / 180;
      final dx = centerX + 36 * math.cos(angle);
      final dy = centerY + 36 * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.6, dotPaint);
    }

    final innerCirclePaint = Paint()
      ..color = const Color(0xFF0F0C0A)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), 30, innerCirclePaint);

    const textSpan = TextSpan(
      text: '🚩\n ॐ',
      style: TextStyle(
        fontSize: 15,
        height: 0.95,
        color: Color(0xFFFF8C00),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

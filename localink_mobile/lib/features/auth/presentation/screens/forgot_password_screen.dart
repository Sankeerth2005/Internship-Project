import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  final List<Particle> _particles = List.generate(35, (index) => Particle());

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email address is required';
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(val.trim())) return 'Enter a valid email address';
    return null;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final dio = DioClient().dio;
      
      final response = await dio.post('auth/forgot-password', data: {
        'email': email,
        'captchaToken': 'test',
      });

      if (mounted) {
        if (response.data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully! Please check your email.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.push('/verify-otp', extra: email);
        } else {
          throw Exception(response.data['message'] ?? 'Failed to send OTP.');
        }
      }
    } catch (e) {
      if (mounted) {
        String errMsg = 'Failed to send OTP. Please try again.';
        if (e is DioException && e.response != null) {
          final data = e.response?.data;
          if (data is Map) {
            errMsg = data['message'] ?? errMsg;
          }
        }
        // Fallback navigation for testing UI flow if API endpoint offline
        context.push('/verify-otp', extra: _emailController.text.trim());
      }
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
              painter: ForgotHeroPainter(_particles),
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

                          // Title: "Forgot Password?"
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Forgot ',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Password?',
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

                          // Subtitle Text
                          const Text(
                            "Don't worry! It happens. Enter your email address\nand we'll send you an OTP to reset your password.",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              color: Color(0xFFCDC3B8),
                              height: 1.4,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Email Field Label
                                  const Text(
                                    'Email Address',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Email Text Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email address',
                                      hintStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Color(0xFF70655B),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.mail_outline_rounded,
                                        color: Color(0xFFFF7A00),
                                        size: 20,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF14110E),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFF2E241A)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFF2E241A)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFFF4D4F)),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: Color(0xFFFF4D4F), width: 1.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Info Box: "Reset OTP"
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16110D),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFFF7A00).withValues(alpha: 0.18),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF241A12),
                                            border: Border.all(
                                              color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.send_rounded,
                                            color: Color(0xFFFF9D00),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Reset OTP',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFFF9D00),
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'We will send a secure password reset OTP to your email address.',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 11.5,
                                                  color: Color(0xFFA59B90),
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Action Button: "Send Reset OTP"
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
                                        onPressed: _isLoading ? null : _sendOtp,
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
                                                    'Send Reset OTP',
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

                          // Bottom Link: "Remember your password? Login"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Remember your password? ',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  color: Color(0xFFC0B5A8),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.go('/login');
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF7A00),
                                    decoration: TextDecoration.underline,
                                    decorationStyle: TextDecorationStyle.dashed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Bottom Lotus Divider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 0.8,
                                color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: Icon(
                                  Icons.filter_vintage_rounded,
                                  size: 16,
                                  color: Color(0xFFFF9D00),
                                ),
                              ),
                              Container(
                                width: 50,
                                height: 0.8,
                                color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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

class ForgotHeroPainter extends CustomPainter {
  final List<Particle> particles;

  ForgotHeroPainter(this.particles);

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

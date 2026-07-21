import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? selectedRole;

  const LoginScreen({super.key, this.selectedRole});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  final List<Particle> _particles = List.generate(35, (index) => Particle());

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email address is required';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    if (value.length > 100) return 'Too long';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        final cleanMsg = next.message.replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMsg),
            backgroundColor: const Color(0xFFFF4D4F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is AuthAuthenticated) {
        final role = next.userType.toLowerCase().trim();
        if (role == 'admin') {
          context.go('/admin-dashboard');
        } else if (role == 'client' || role == 'businessowner') {
          context.go('/business-dashboard');
        } else {
          context.go('/home');
        }
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070605),
      body: Stack(
        children: [
          // ─── 1. TOP HERO ARTWORK CANVAS (VECTOR DRAWING - NO TEXT OVERLAP) ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: CustomPaint(
              painter: LoginHeroPainter(_particles),
            ),
          ),

          // ─── 2. MAIN SCROLLABLE LOGIN BODY ───
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 140), // Clearance below top Om gear emblem

                    // Top Branding Header
                    const Text(
                      'VOCAL FOR',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 2.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFFFE5A3),
                            Color(0xFFFFB834),
                            Color(0xFFFF8C00),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'SANATAN',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 3.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle: CONNECT • PRESERVE • EMPOWER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 1,
                          color: const Color(0xFFFF9D00).withValues(alpha: 0.4),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.diamond_rounded, size: 6, color: Color(0xFFFF9D00)),
                        ),
                        const Text(
                          'CONNECT  •  PRESERVE  •  EMPOWER',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD0C0B0),
                            letterSpacing: 1.8,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.diamond_rounded, size: 6, color: Color(0xFFFF9D00)),
                        ),
                        Container(
                          width: 30,
                          height: 1,
                          color: const Color(0xFFFF9D00).withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── 3. MAIN LOGIN CARD CONTAINER ───
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
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Title: "Welcome Back"
                            Center(
                              child: Column(
                                children: [
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Welcome ',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 25,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Back',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 25,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFFF6A00),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Login to continue your journey',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.5,
                                      color: Color(0xFFB0A59A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Card Divider: ─── ◆ ───
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 0.8,
                                          color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Icon(Icons.diamond_rounded, size: 7, color: Color(0xFFFF9D00)),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 0.8,
                                          color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Email Address Field
                            _buildLabel('Email Address'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              decoration: _inputDecoration(
                                hint: 'Enter your email address',
                                prefixIcon: Icons.mail_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Password Field
                            _buildLabel('Password'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_showPassword,
                              validator: _validatePassword,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              decoration: _inputDecoration(
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline_rounded,
                              ).copyWith(
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() => _showPassword = !_showPassword),
                                  child: Icon(
                                    _showPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/forgot-password');
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF7A00),
                                    decoration: TextDecoration.underline,
                                    decorationStyle: TextDecorationStyle.dashed,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // ─── LOGIN BUTTON ───
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
                                  onPressed: authState is AuthLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: authState is AuthLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          children: [
                                            const Icon(
                                              Icons.account_balance_rounded,
                                              color: Colors.white70,
                                              size: 22,
                                            ),
                                            const Spacer(),
                                            const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider: ─── ◆ ───
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 0.8,
                                    color: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(Icons.diamond_rounded, size: 7, color: Color(0xFFFF9D00)),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 0.8,
                                    color: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Sign Up Row
                            if (widget.selectedRole?.toLowerCase().trim() != 'admin')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.5,
                                      color: Color(0xFFC0B5A8),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      context.push('/signup', extra: widget.selectedRole);
                                    },
                                    child: const Row(
                                      children: [
                                        Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFFF7A00),
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: Color(0xFFFF7A00),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ─── 4. BOTTOM FOOTER TRUST BADGE ───
                    Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Color(0xFFFF7A00),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Trusted. Verified. Secure.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your data is protected with highest security standards.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: Color(0xFF8C8072),
                          ),
                          textAlign: TextAlign.center,
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: Color(0xFF70655B),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFFFF7A00),
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
      errorStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: Color(0xFFFF4D4F),
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

class LoginHeroPainter extends CustomPainter {
  final List<Particle> particles;

  LoginHeroPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Radial Sunset Aura
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

    // 2. Starry Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      particlePaint.color = const Color(0xFFFF9D00).withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        2.0,
        particlePaint,
      );
    }

    // 3. Flowing Golden Wave Curves
    final wavePaint = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(size.width * 0.3, size.height * 0.3, size.width * 0.7, size.height * 0.7, size.width, size.height * 0.4);

    canvas.drawPath(path1, wavePaint);

    // 4. Temple Spires Silhouette Artwork
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

    // 5. Central Gear Ring & Om Flag Badge
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

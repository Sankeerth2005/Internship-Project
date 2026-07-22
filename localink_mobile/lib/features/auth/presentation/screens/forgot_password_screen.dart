import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../shared/presentation/widgets/app_text_field.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../shared/presentation/widgets/shake_widget.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../../core/theme/app_theme.dart';

// ─── DESIGN TOKENS (aligned to DESIGN_SYSTEM.md) ─────────────────────────────
class _Tok {
  static const Color primary  = Color(0xFFFF6600);
  static const Color white    = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1A1918);
  static const Color medText  = Color(0xFF5F5C58);
  static const Color surface  = Color(0xFFF9F8F6);
  static const Color border   = Color(0xFFEAE8E3);

  // Radii
  static const double rMd = 12;
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  
  bool _isLoading = false;
  bool _emailFocused = false;

  // Animation controllers
  late final AnimationController _entranceCtrl;
  late final AnimationController _iconFloatCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _iconFloat;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _emailFocus.addListener(() {
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
  }

  void _initAnimations() {
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    _iconFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _iconFloat = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _iconFloatCtrl, curve: Curves.easeInOutSine),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _entranceCtrl.dispose();
    _iconFloatCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email is required';
    final emailRegExp = RegExp(r'^[a-zA-Z][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(val.trim())) return 'Invalid email format';
    return null;
  }

  // ── PRESERVED LOGIC (DO NOT MODIFY) ────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      _shakeKey.currentState?.shake();
      return;
    }

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
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully! Please check your email inbox.'),
              backgroundColor: AppTheme.tricolorGreen,
            ),
          );
          context.push('/verify-otp', extra: email);
        } else {
          throw Exception(response.data['message'] ?? 'Failed to send verification code.');
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _shakeKey.currentState?.shake();
        String errMsg = 'Failed to send code. Please try again.';
        if (e is DioException && e.response != null) {
          final data = e.response?.data;
          if (data is Map) {
            errMsg = data['message'] ?? errMsg;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: _Tok.white,
      body: Stack(
        children: [
          // Background visual radial paint
          Positioned.fill(
            child: CustomPaint(
              painter: _ForgotGlowPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header back navigation button
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 12),
                  child: Semantics(
                    button: true,
                    label: 'Go back',
                    child: _BackButton(onPressed: () => context.pop()),
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: ShakeWidget(
                        key: _shakeKey,
                        child: Center(
                          child: AppCard(
                            maxWidth: 440,
                            padding: isMobile ? const EdgeInsets.all(24) : const EdgeInsets.all(40),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Lock Reset Icon Emblem
                                  AnimatedBuilder(
                                    animation: _entranceCtrl,
                                    builder: (_, child) => Opacity(
                                      opacity: _headerFade.value,
                                      child: Transform.scale(
                                        scale: _headerFade.value,
                                        child: child,
                                      ),
                                    ),
                                    child: AnimatedBuilder(
                                      animation: _iconFloat,
                                      builder: (_, child) => Transform.translate(
                                        offset: Offset(0, _iconFloat.value),
                                        child: child,
                                      ),
                                      child: _IconBadge(),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Heading Text
                                  AnimatedBuilder(
                                    animation: _entranceCtrl,
                                    builder: (_, child) => FadeTransition(
                                      opacity: _headerFade,
                                      child: SlideTransition(
                                        position: _headerSlide,
                                        child: child,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Forgot Password',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: _Tok.charcoal,
                                            letterSpacing: -0.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),

                                        // Friendly copywriting explanation
                                        const Text(
                                          'Enter the email address connected to your account. We will send you a 6-digit verification code to reset your password securely.',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13.5,
                                            height: 1.45,
                                            color: _Tok.medText,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Email text input
                                  AnimatedBuilder(
                                    animation: _entranceCtrl,
                                    builder: (_, child) => FadeTransition(
                                      opacity: _formFade,
                                      child: SlideTransition(
                                        position: _formSlide,
                                        child: child,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        _AnimatedFieldGlow(
                                          isFocused: _emailFocused,
                                          child: AppTextField(
                                            controller: _emailController,
                                            labelText: 'Email Address',
                                            hintText: 'Enter your registered email',
                                            keyboardType: TextInputType.emailAddress,
                                            prefixIcon: Icons.mail_outline_rounded,
                                            validator: _validateEmail,
                                            focusNode: _emailFocus,
                                            autofillHints: const [AutofillHints.email],
                                            textInputAction: TextInputAction.done,
                                            onFieldSubmitted: (_) => _sendOtp(),
                                          ),
                                        ),
                                        const SizedBox(height: 28),

                                        // Submit button
                                        AppButton(
                                          label: 'Send OTP',
                                          isLoading: _isLoading,
                                          onPressed: _sendOtp,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

class _IconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primarySolarGradient,
          boxShadow: [
            BoxShadow(
              color: _Tok.primary.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: _Tok.white,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.lock_reset_rounded,
              color: _Tok.primary,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedFieldGlow extends StatelessWidget {
  final bool isFocused;
  final Widget child;

  const _AnimatedFieldGlow({
    required this.isFocused,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_Tok.rMd),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: _Tok.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _Tok.surface,
            borderRadius: BorderRadius.circular(_Tok.rMd),
            border: Border.all(color: _Tok.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: _Tok.charcoal,
          ),
        ),
      ),
    );
  }
}

class _ForgotGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9E4F).withValues(alpha: 0.055),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.9));
    canvas.drawRect(rect, p1);

    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6600).withValues(alpha: 0.038),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: size.width * 0.9));
    canvas.drawRect(rect, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

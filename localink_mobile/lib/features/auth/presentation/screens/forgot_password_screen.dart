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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email is required';
    final emailRegExp = RegExp(r'^[a-zA-Z][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(val.trim())) return 'Invalid email format';
    return null;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.warningImpact();
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
        HapticFeedback.errorImpact();
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
      backgroundColor: Colors.white,
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
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.accentColor, size: 24),
                      onPressed: () => context.pop(),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48), // tap target size
                      ),
                    ),
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
                            maxWidth: 420,
                            padding: isMobile ? const EdgeInsets.all(20) : const EdgeInsets.all(40),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Lock Reset Icon Emblem
                                  Center(
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppTheme.primarySolarGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accentColor.withOpacity(0.2),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.lock_reset_rounded,
                                            color: AppTheme.accentColor,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Heading Text
                                  const Text(
                                    'Forgot Password',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1918),
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
                                      fontSize: 13,
                                      height: 1.4,
                                      color: Color(0xFF5F5C58),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),

                                  // Email text input
                                  AppTextField(
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
                                  const SizedBox(height: 24),

                                  // Submit button
                                  AppButton(
                                    label: 'Send OTP',
                                    isLoading: _isLoading,
                                    onPressed: _sendOtp,
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

class _ForgotGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9E4F).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.9));
    canvas.drawRect(rect, p1);

    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6600).withOpacity(0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: size.width * 0.9));
    canvas.drawRect(rect, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

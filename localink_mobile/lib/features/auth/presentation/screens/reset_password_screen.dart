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
import '../../../shared/presentation/widgets/app_dialog.dart';
import '../../../../core/theme/app_theme.dart';

// ─── DESIGN TOKENS (aligned to DESIGN_SYSTEM.md) ─────────────────────────────
class _Tok {
  static const Color primary  = Color(0xFFFF6600);
  static const Color white    = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1A1918);
  static const Color medText  = Color(0xFF5F5C58);
  static const Color mutedText = Color(0xFF9F9B96);
  static const Color surface  = Color(0xFFF9F8F6);
  static const Color border   = Color(0xFFEAE8E3);

  // Radii
  static const double rMd = 12;
}

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _passwordFocused = false;
  bool _confirmPasswordFocused = false;

  // Staggered entrance animations
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
    _passwordController.addListener(_onPasswordChanged);
    _setupFocusListeners();
    _initAnimations();
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

  void _setupFocusListeners() {
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
    _confirmPasswordFocus.addListener(() {
      setState(() => _confirmPasswordFocused = _confirmPasswordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _entranceCtrl.dispose();
    _iconFloatCtrl.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {}); // Updates requirement checkmarks dynamically
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Password is required';
    if (val.length < 8) return 'Password must be at least 8 characters';
    
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(val);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(val);
    final hasDigits = RegExp(r'[0-9]').hasMatch(val);
    final hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val);

    if (!hasUppercase) return 'Must contain at least one uppercase letter';
    if (!hasLowercase) return 'Must contain at least one lowercase letter';
    if (!hasDigits) return 'Must contain at least one number';
    if (!hasSpecialCharacters) return 'Must contain at least one special character';

    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Confirm password is required';
    if (val != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ── PRESERVED LOGIC (DO NOT MODIFY) ────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      _shakeKey.currentState?.shake();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = DioClient().dio;
      final response = await dio.post('auth/reset-password', data: {
        'email': widget.email,
        'otp': widget.otp,
        'newPassword': _passwordController.text,
      });

      if (mounted) {
        if (response.data['success'] == true) {
          HapticFeedback.mediumImpact();
          AppDialog.showSuccess(
            context: context,
            title: 'Password Reset!',
            message: 'Your password has been changed. Redirecting to login...',
          ).then((_) {
            if (mounted) {
              context.go('/login');
            }
          });
        } else {
          throw Exception(response.data['message'] ?? 'Failed to reset password.');
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _shakeKey.currentState?.shake();
        String errMsg = 'Failed to reset password. Please try again.';
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
              painter: _ResetGlowPainter(),
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
                                  // Reset Icon Emblem
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

                                  // Heading Title
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
                                          'Reset Password',
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

                                        // Reassuring explanation
                                        Text(
                                          'Create a strong, secure new password for your account:\n${widget.email}',
                                          style: const TextStyle(
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

                                  // Form Container
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
                                        // New Password Input field
                                        _AnimatedFieldGlow(
                                          isFocused: _passwordFocused,
                                          child: AppTextField(
                                            controller: _passwordController,
                                            labelText: 'New Password',
                                            hintText: 'Enter new password',
                                            isPassword: true,
                                            prefixIcon: Icons.lock_outline_rounded,
                                            validator: _validatePassword,
                                            focusNode: _passwordFocus,
                                            autofillHints: const [AutofillHints.newPassword],
                                            textInputAction: TextInputAction.next,
                                            onFieldSubmitted: (_) {
                                              FocusScope.of(context).requestFocus(_confirmPasswordFocus);
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        // Requirements Checklist
                                        _buildPasswordChecklist(),
                                        const SizedBox(height: 16),

                                        // Confirm Password Input field
                                        _AnimatedFieldGlow(
                                          isFocused: _confirmPasswordFocused,
                                          child: AppTextField(
                                            controller: _confirmPasswordController,
                                            labelText: 'Confirm Password',
                                            hintText: 'Re-enter new password',
                                            isPassword: true,
                                            prefixIcon: Icons.lock_outline_rounded,
                                            validator: _validateConfirmPassword,
                                            focusNode: _confirmPasswordFocus,
                                            autofillHints: const [AutofillHints.newPassword],
                                            textInputAction: TextInputAction.done,
                                            onFieldSubmitted: (_) => _resetPassword(),
                                          ),
                                        ),
                                        const SizedBox(height: 32),

                                        // Submit button
                                        AppButton(
                                          label: 'Reset Password',
                                          isLoading: _isLoading,
                                          onPressed: _resetPassword,
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

  Widget _buildPasswordChecklist() {
    final text = _passwordController.text;
    final hasMin8 = text.length >= 8;
    final hasUpper = text.contains(RegExp(r'[A-Z]'));
    final hasLower = text.contains(RegExp(r'[a-z]'));
    final hasDigit = text.contains(RegExp(r'[0-9]'));
    final hasSpecial = text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Tok.surface,
        borderRadius: BorderRadius.circular(_Tok.rMd),
        border: Border.all(color: _Tok.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password requirements:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _Tok.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          _buildChecklistItem('Minimum 8 characters', hasMin8),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one uppercase letter (A-Z)', hasUpper),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one lowercase letter (a-z)', hasLower),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one number (0-9)', hasDigit),
          const SizedBox(height: 6),
          _buildChecklistItem('At least one special character (!@#\$%^&*)', hasSpecial),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isCompleted) {
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isCompleted ? const Color(0xFF1E824C) : _Tok.mutedText,
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: isCompleted ? _Tok.charcoal : _Tok.medText,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
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
              Icons.lock_open_rounded,
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

class _ResetGlowPainter extends CustomPainter {
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
  bool shouldRepaint(covariant _ResetGlowPainter oldDelegate) => false;
}

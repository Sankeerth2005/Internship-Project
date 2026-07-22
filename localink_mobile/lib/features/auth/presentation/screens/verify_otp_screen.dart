import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../shared/presentation/widgets/shake_widget.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/app_back_button.dart';
import '../../../shared/presentation/widgets/animated_field_glow.dart';
import '../../../shared/presentation/widgets/app_background.dart';
import '../../../shared/presentation/widgets/brand_icon_badge.dart';
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

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  
  // Single hidden controller that holds the combined 6 digit OTP for validation
  final _otpController = TextEditingController();

  // 6 Individual controllers & focus nodes for the boxes
  final List<TextEditingController> _boxControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  
  // Resend OTP Countdown
  int _resendCountdown = 60;
  Timer? _countdownTimer;

  // Staggered entrance animations
  late final AnimationController _entranceCtrl;
  late final AnimationController _iconFloatCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _iconFloat;

  // Focus tracking for highlight glows
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initAnimations();
    _setupFocusListeners();
    
    // Auto-focus the first box after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
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

  void _setupFocusListeners() {
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() {
            _focusedIndex = i;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    for (var controller in _boxControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _entranceCtrl.dispose();
    _iconFloatCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        _countdownTimer?.cancel();
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  void _updateOtpControllerValue() {
    final buffer = StringBuffer();
    for (var controller in _boxControllers) {
      buffer.write(controller.text.trim());
    }
    _otpController.text = buffer.toString();
  }

  String? _validateOtp(String? val) {
    final cleanVal = _otpController.text.trim();
    if (cleanVal.isEmpty) return 'Please enter the code';
    if (cleanVal.length != 6 || int.tryParse(cleanVal) == null) {
      return 'Please enter all 6 digits';
    }
    return null;
  }

  // ── PRESERVED LOGIC (DO NOT MODIFY) ────────────────────────────────────────
  void _verifyOtp() {
    _updateOtpControllerValue();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      _shakeKey.currentState?.shake();
      return;
    }

    setState(() => _isLoading = true);

    try {
      HapticFeedback.mediumImpact();
      context.push('/reset-password', extra: {
        'email': widget.email,
        'otp': _otpController.text.trim(),
      });
    } catch (e) {
      HapticFeedback.heavyImpact();
      _shakeKey.currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification process encountered an issue. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final dio = DioClient().dio;
      final response = await dio.post('auth/forgot-password', data: {
        'email': widget.email,
        'captchaToken': 'test',
      });
      if (response.data['success'] == true) {
        HapticFeedback.mediumImpact();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A fresh verification code has been sent to your email.'),
            backgroundColor: AppTheme.tricolorGreen,
          ),
        );
        _startTimer();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to resend code.');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _shakeKey.currentState?.shake();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resending verification code failed. Please check connection.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
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
      body: AppBackground(
        child: Stack(
          children: [
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
                      child: AppBackButton(onPressed: () => context.pop()),
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
                                    // Verification Icon Emblem
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
                                        child: const BrandIconBadge(
                                          icon: Icons.verified_user_rounded,
                                          size: 72,
                                        ),
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
                                            'Verify Code',
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

                                          // Friendly explanation
                                          Text(
                                            'We have sent a 6-digit verification code to:\n${widget.email}\nEnter it below to proceed.',
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

                                    // Premium 6-Box Code Input layout
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
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: List.generate(6, (index) {
                                              final isFocused = _focusedIndex == index && _focusNodes[index].hasFocus;
                                              return SizedBox(
                                                width: isMobile ? 46 : 52,
                                                height: 56,
                                                child: KeyboardListener(
                                                  focusNode: FocusNode(), // intercept keyboard key events
                                                  onKeyEvent: (event) {
                                                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                                                      if (_boxControllers[index].text.isEmpty && index > 0) {
                                                        _boxControllers[index - 1].clear();
                                                        _focusNodes[index - 1].requestFocus();
                                                        _updateOtpControllerValue();
                                                      }
                                                    }
                                                  },
                                                  child: AnimatedFieldGlow(
                                                    isFocused: isFocused,
                                                    child: TextFormField(
                                                      controller: _boxControllers[index],
                                                      focusNode: _focusNodes[index],
                                                      keyboardType: TextInputType.number,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: _Tok.charcoal,
                                                      ),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.digitsOnly,
                                                      ],
                                                      decoration: InputDecoration(
                                                        counterText: '',
                                                        isDense: true,
                                                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                                        fillColor: _Tok.surface,
                                                        filled: true,
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(_Tok.rMd),
                                                          borderSide: const BorderSide(color: _Tok.border),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(_Tok.rMd),
                                                          borderSide: const BorderSide(color: _Tok.primary, width: 2),
                                                        ),
                                                      ),
                                                      onChanged: (value) {
                                                        if (value.length > 1) {
                                                          // Clipboard code paste distribution
                                                          final cleanCode = value.replaceAll(RegExp(r'\D'), '');
                                                          if (cleanCode.length >= 6) {
                                                            for (int j = 0; j < 6; j++) {
                                                              _boxControllers[j].text = cleanCode[j];
                                                            }
                                                            _focusNodes[5].requestFocus();
                                                            _updateOtpControllerValue();
                                                            _verifyOtp(); // Auto-verify on valid paste
                                                          } else {
                                                            _boxControllers[index].text = value.substring(value.length - 1);
                                                            if (index < 5) _focusNodes[index + 1].requestFocus();
                                                            _updateOtpControllerValue();
                                                          }
                                                        } else if (value.isNotEmpty) {
                                                          if (index < 5) {
                                                            _focusNodes[index + 1].requestFocus();
                                                          } else {
                                                            _updateOtpControllerValue();
                                                            _verifyOtp(); // Auto-verify on final digit typed
                                                          }
                                                        }
                                                        _updateOtpControllerValue();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                          
                                          // Validation error container for combined otp
                                          FormField<String>(
                                            validator: _validateOtp,
                                            builder: (state) {
                                              if (state.hasError) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 12.0),
                                                  child: Text(
                                                    state.errorText ?? '',
                                                    style: const TextStyle(
                                                      color: AppTheme.errorColor,
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                          const SizedBox(height: 28),

                                          // Resend timer and Action Link
                                          Center(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _resendCountdown > 0
                                                      ? 'Resend code in '
                                                      : "Didn't receive code?  ",
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 13.5,
                                                    color: _Tok.medText,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: _resendCountdown == 0 ? _resendOtp : null,
                                                  child: Text(
                                                    _resendCountdown > 0
                                                        ? '${_resendCountdown}s'
                                                        : 'Resend OTP',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: _resendCountdown > 0
                                                          ? _Tok.mutedText
                                                          : _Tok.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 28),

                                          // Core CTA button
                                          AppButton(
                                            label: 'Verify OTP',
                                            isLoading: _isLoading,
                                            onPressed: _verifyOtp,
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
      ),
    );
  }
}

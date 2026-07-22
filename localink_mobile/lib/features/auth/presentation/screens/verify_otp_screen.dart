import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../shared/presentation/widgets/shake_widget.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../../core/theme/app_theme.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
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

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus the first box after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
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

  void _verifyOtp() {
    _updateOtpControllerValue();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.warningImpact();
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
      HapticFeedback.errorImpact();
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
      HapticFeedback.errorImpact();
      _shakeKey.currentState?.shake();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resending verification code failed. Please check connection.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
          // Background visual radial glows
          Positioned.fill(
            child: CustomPaint(
              painter: _VerifyGlowPainter(),
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
                        minimumSize: const Size(48, 48),
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
                                  // Verification Icon Emblem
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
                                            Icons.verified_user_rounded,
                                            color: AppTheme.accentColor,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Heading Title
                                  const Text(
                                    'Verify Code',
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

                                  // Friendly explanation
                                  Text(
                                    'We have sent a 6-digit verification code to:\n${widget.email}\nEnter it below to proceed.',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      height: 1.4,
                                      color: Color(0xFF5F5C58),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),

                                  // Premium 6-Box Code Input layout
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(6, (index) {
                                      return SizedBox(
                                        width: isMobile ? 44 : 50,
                                        height: 54,
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
                                          child: TextFormField(
                                            controller: _boxControllers[index],
                                            focusNode: _focusNodes[index],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1918),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                            ],
                                            decoration: InputDecoration(
                                              counterText: '',
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: AppTheme.borderColor),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
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
                                      );
                                    }),
                                  ),
                                  
                                  // Validation error container for combined otp
                                  FormField<String>(
                                    validator: _validateOtp,
                                    builder: (state) {
                                      if (state.hasError) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            state.errorText ?? '',
                                            style: const TextStyle(
                                              color: AppTheme.errorColor,
                                              fontSize: 12,
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
                                              : "Didn't receive code? ",
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            color: Color(0xFF5F5C58),
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
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _resendCountdown > 0
                                                  ? AppTheme.mutedTextColor
                                                  : AppTheme.accentColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Core CTA button
                                  AppButton(
                                    label: 'Verify OTP',
                                    isLoading: _isLoading,
                                    onPressed: _verifyOtp,
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

class _VerifyGlowPainter extends CustomPainter {
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
  bool shouldRepaint(covariant _VerifyGlowPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String? _validateOtp(String? val) {
    if (val == null || val.trim().isEmpty) return 'OTP is required';
    if (val.trim().length != 6 || int.tryParse(val.trim()) == null) {
      return 'OTP must be a 6-digit number';
    }
    return null;
  }

  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final otp = _otpController.text.trim();
      
      // On verify success, navigate to reset password page carrying credentials
      context.push('/reset-password', extra: {
        'email': widget.email,
        'otp': otp,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFC8A97E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We have sent a 6-digit validation OTP code to:\n${widget.email}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  const Text(
                    'Verification Code',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: _validateOtp,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        letterSpacing: 8,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC8A97E)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF4D4F)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF4D4F), width: 2),
                      ),
                      errorStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFFFF4D4F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC8A97E), Color(0xFFE6C89F)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC8A97E).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _verifyOtp,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

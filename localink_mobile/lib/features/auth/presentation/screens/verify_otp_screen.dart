import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/animated_background.dart';

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
      body: AnimatedAuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF7A00)),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              Expanded(
                child: Center(
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
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
                                ),
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  color: Color(0xFFFF7A00),
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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
                                  borderSide: const BorderSide(color: Color(0xFFFF7A00)),
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
                                  colors: [Color(0xFFFF7A00), Color(0xFFFF9A3C)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

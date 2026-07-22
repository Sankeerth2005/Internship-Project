import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../../shared/presentation/widgets/app_text_field.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../shared/presentation/widgets/app_card.dart';
import '../../../shared/presentation/widgets/shake_widget.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? selectedRole;

  const LoginScreen({super.key, this.selectedRole});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    } else {
      HapticFeedback.mediumImpact();
      _shakeKey.currentState?.shake();
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
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
        HapticFeedback.heavyImpact();
        _shakeKey.currentState?.shake();
        final cleanMsg = next.message.replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMsg),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } else if (next is AuthAuthenticated) {
        HapticFeedback.mediumImpact();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ambient Radial Background Glows
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginGlowPainter(),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                            // Hero Logo Header Badge
                            Center(
                              child: Hero(
                                tag: 'app_logo',
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.primarySolarGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.accentColor.withOpacity(0.25),
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
                                        child: Text(
                                          'ॐ',
                                          style: TextStyle(
                                            color: AppTheme.accentColor,
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Heading Title
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1918),
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),

                            // Trust Statement & Profile Badge Label
                            Builder(
                              builder: (context) {
                                final role = widget.selectedRole?.toLowerCase().trim();
                                String statement = 'Discover local businesses with community trust.';
                                if (role == 'admin') {
                                  statement = 'Platform governance and configuration portal.';
                                } else if (role == 'businessowner') {
                                  statement = 'Manage your store listings and customer leads.';
                                }
                                return Text(
                                  statement,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF5F5C58),
                                    height: 1.35,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                            const SizedBox(height: 28),

                            // Email Text Input Field
                            AppTextField(
                              controller: _emailController,
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.mail_outline_rounded,
                              validator: _validateEmail,
                              autofillHints: const [AutofillHints.email],
                              focusNode: _emailFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_passwordFocus);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Text Input Field
                            AppTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              isPassword: true,
                              prefixIcon: Icons.lock_outline_rounded,
                              validator: _validatePassword,
                              autofillHints: const [AutofillHints.password],
                              focusNode: _passwordFocus,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 8),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: Semantics(
                                button: true,
                                label: 'Forgot password reset link',
                                child: TextButton(
                                  onPressed: () => context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.accentColor,
                                    minimumSize: const Size(48, 36),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Core CTA Login Button
                            AppButton(
                              label: 'Login',
                              isLoading: authState is AuthLoading,
                              onPressed: _login,
                            ),
                            const SizedBox(height: 20),

                            // Biometrics Placeholder
                            Center(
                              child: Semantics(
                                button: true,
                                label: 'Biometric fingerprint placeholder',
                                child: IconButton(
                                  icon: const Icon(Icons.fingerprint_rounded, size: 28),
                                  color: AppTheme.accentColor,
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Biometrics placeholder. Authenticate using password above.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Signup Redirection (hidden for admin)
                            if (widget.selectedRole?.toLowerCase().trim() != 'admin') ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.5,
                                      color: Color(0xFF5F5C58),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push('/signup', extra: widget.selectedRole),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }
}

// Subtle Radial Gradient Painter for background visuals
class _LoginGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Subtle top-left Saffron Glow
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9E4F).withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.9));
    canvas.drawRect(rect, p1);

    // Subtle bottom-right Saffron Glow
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

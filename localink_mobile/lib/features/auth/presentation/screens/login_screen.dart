import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../../shared/presentation/widgets/app_text_field.dart';
import '../../../shared/presentation/widgets/app_button.dart';
import '../../../shared/presentation/widgets/shake_widget.dart';
import '../../../../core/theme/app_theme.dart';

// ─── DESIGN TOKENS (aligned to DESIGN_SYSTEM.md) ─────────────────────────────
class _Tok {
  // Colors
  static const Color primary  = Color(0xFFFF6600);
  static const Color white    = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1A1918);
  static const Color medText  = Color(0xFF5F5C58);
  static const Color surface  = Color(0xFFF9F8F6);
  static const Color border   = Color(0xFFEAE8E3);

  // Spacing (4dp grid)
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 24;
  static const double xxl = 32;

  // Radii
  static const double rMd    = 12;
  static const double rRound = 999;
}

// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  final String? selectedRole;

  const LoginScreen({super.key, this.selectedRole});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── Keys & Controllers ────────────────────────────────────────────────────
  final _formKey   = GlobalKey<FormState>();
  final _shakeKey  = GlobalKey<ShakeWidgetState>();

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  final FocusNode _emailFocus    = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final AnimationController _logoFloatCtrl;

  late final Animation<double>  _headerFade;
  late final Animation<Offset>  _headerSlide;
  late final Animation<double>  _formFade;
  late final Animation<Offset>  _formSlide;
  late final Animation<double>  _ctaFade;
  late final Animation<double>  _logoFloat;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _emailFocused    = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupFocusListeners();
  }

  void _initAnimations() {
    // Staggered entrance
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.30, 0.80, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.30, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    // Logo gentle float loop
    _logoFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _logoFloat = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _logoFloatCtrl, curve: Curves.easeInOutSine),
    );

    _entranceCtrl.forward();
  }

  void _setupFocusListeners() {
    _emailFocus.addListener(() {
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _entranceCtrl.dispose();
    _logoFloatCtrl.dispose();
    super.dispose();
  }

  // ── PRESERVED AUTHENTICATION LOGIC (DO NOT MODIFY) ───────────────────────
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
  // ─────────────────────────────────────────────────────────────────────────

  String get _roleStatement {
    final role = widget.selectedRole?.toLowerCase().trim();
    if (role == 'admin')         return 'Platform governance and configuration portal.';
    if (role == 'businessowner') return 'Manage your store listings and customer leads.';
    return 'Discover local businesses with community trust.';
  }

  @override
  Widget build(BuildContext context) {
    // ── PRESERVED AUTH LISTENER (DO NOT MODIFY) ──────────────────────────
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
    // ──────────────────────────────────────────────────────────────────────

    final authState  = ref.watch(authProvider);
    final isLoading  = authState is AuthLoading;
    final size       = MediaQuery.of(context).size;
    final bottomPad  = MediaQuery.of(context).padding.bottom;
    final isMobile   = size.width < 600;
    final hPad       = isMobile ? _Tok.xl : _Tok.xxl;

    return Scaffold(
      backgroundColor: _Tok.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background ───────────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _LoginBgPainter()),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  _Tok.xxl,
                  hPad,
                  math.max(bottomPad + _Tok.xl, _Tok.xxl),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ShakeWidget(
                    key: _shakeKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Logo + Header ────────────────────────────────
                        _buildHeader(),

                        const SizedBox(height: _Tok.xxl),

                        // ── Role badge ───────────────────────────────────
                        _buildRoleBadge(),

                        const SizedBox(height: _Tok.xxl),

                        // ── Form fields ──────────────────────────────────
                        _buildForm(isLoading),

                        const SizedBox(height: _Tok.xl),

                        // ── CTAs ─────────────────────────────────────────
                        _buildCTAs(isLoading),

                        SizedBox(height: _Tok.xl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Back button ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: _Tok.sm, top: _Tok.sm),
              child: Semantics(
                button: true,
                label: 'Go back to role selection',
                child: _BackButton(onPressed: () => context.go('/welcome')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo + Header section ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) => FadeTransition(
        opacity: _headerFade,
        child: SlideTransition(position: _headerSlide, child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Floating logo
          AnimatedBuilder(
            animation: _logoFloat,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _logoFloat.value),
              child: child,
            ),
            child: _LogoBadge(),
          ),

          const SizedBox(height: _Tok.xl),

          // Title
          Text(
            'Welcome Back',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _Tok.charcoal,
              letterSpacing: -0.6,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: _Tok.sm),

          // Subtitle
          Text(
            _roleStatement,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _Tok.medText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Role badge ────────────────────────────────────────────────────────────
  Widget _buildRoleBadge() {
    final role = widget.selectedRole?.toLowerCase().trim();
    if (role == null) return const SizedBox.shrink();

    String label;
    IconData icon;
    if (role == 'admin') {
      label = 'Admin Portal';
      icon  = Icons.admin_panel_settings_rounded;
    } else if (role == 'businessowner') {
      label = 'Business Owner';
      icon  = Icons.storefront_rounded;
    } else {
      label = 'Consumer';
      icon  = Icons.person_rounded;
    }

    return AnimatedBuilder(
      animation: _headerFade,
      builder: (_, child) => Opacity(opacity: _headerFade.value, child: child),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _Tok.lg,
            vertical: _Tok.sm,
          ),
          decoration: BoxDecoration(
            color: _Tok.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(_Tok.rRound),
            border: Border.all(
              color: _Tok.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: _Tok.primary),
              const SizedBox(width: _Tok.xs),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _Tok.primary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm(bool isLoading) {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) => FadeTransition(
        opacity: _formFade,
        child: SlideTransition(position: _formSlide, child: child),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Email field ─────────────────────────────────────────────
            _AnimatedFieldContainer(
              isFocused: _emailFocused,
              child: AppTextField(
                controller: _emailController,
                labelText: 'Email address',
                hintText: 'you@example.com',
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
            ),

            const SizedBox(height: _Tok.lg),

            // ── Password field ──────────────────────────────────────────
            _AnimatedFieldContainer(
              isFocused: _passwordFocused,
              child: AppTextField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Enter your password',
                isPassword: true,
                prefixIcon: Icons.lock_outline_rounded,
                validator: _validatePassword,
                autofillHints: const [AutofillHints.password],
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => isLoading ? null : _login(),
              ),
            ),

            const SizedBox(height: _Tok.sm),

            // ── Forgot password ─────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: 'Navigate to forgot password screen',
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  style: TextButton.styleFrom(
                    foregroundColor: _Tok.primary,
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: _Tok.sm,
                      vertical: _Tok.xs,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _Tok.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CTAs ──────────────────────────────────────────────────────────────────
  Widget _buildCTAs(bool isLoading) {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) => FadeTransition(
        opacity: _ctaFade,
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary login button
          Semantics(
            button: true,
            label: widget.selectedRole == 'admin'
                ? 'Login as admin'
                : 'Login to your account',
            child: AppButton(
              label: widget.selectedRole?.toLowerCase() == 'admin'
                  ? 'Login as Admin'
                  : 'Login',
              isLoading: isLoading,
              onPressed: isLoading ? null : _login,
            ),
          ),

          const SizedBox(height: _Tok.lg),

          // Biometric placeholder
          Semantics(
            button: true,
            label: 'Biometric fingerprint login placeholder',
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Biometric login coming soon. Use password above.',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(_Tok.rRound),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _Tok.xl,
                  vertical: _Tok.md,
                ),
                decoration: BoxDecoration(
                  color: _Tok.surface,
                  borderRadius: BorderRadius.circular(_Tok.rRound),
                  border: Border.all(color: _Tok.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fingerprint_rounded,
                      size: 22,
                      color: _Tok.primary,
                    ),
                    const SizedBox(width: _Tok.sm),
                    Text(
                      'Use Biometrics',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Tok.medText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: _Tok.xl),

          // Sign-up link (hidden for admin)
          if (widget.selectedRole?.toLowerCase().trim() != 'admin')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?  ",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    color: _Tok.medText,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(
                    '/signup',
                    extra: widget.selectedRole,
                  ),
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _Tok.primary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── LOGO BADGE ───────────────────────────────────────────────────────────────
class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: 'app_logo',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primarySolarGradient,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6600).withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFFF9E4F).withValues(alpha: 0.14),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'ॐ',
                  style: TextStyle(
                    color: Color(0xFFFF6600),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ANIMATED FIELD CONTAINER ─────────────────────────────────────────────────
// Adds a subtle animated left-border accent when the field is focused
class _AnimatedFieldContainer extends StatelessWidget {
  final bool isFocused;
  final Widget child;

  const _AnimatedFieldContainer({
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
                  color: const Color(0xFFFF6600).withValues(alpha: 0.12),
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

// ─── BACK BUTTON ──────────────────────────────────────────────────────────────
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

// ─── BACKGROUND PAINTER ───────────────────────────────────────────────────────
class _LoginBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // White base
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));

    // Top-right saffron bloom
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF9E4F).withValues(alpha: 0.055),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width, 0),
            radius: size.width * 0.9,
          ),
        ),
    );

    // Bottom-left orange bloom
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF6600).withValues(alpha: 0.038),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(0, size.height),
            radius: size.width * 0.85,
          ),
        ),
    );

    // Center subtle warmth
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF9E4F).withValues(alpha: 0.022),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width / 2, size.height * 0.38),
            radius: size.width * 0.55,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}


import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../../../core/theme/app_theme.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
// All values aligned to the 4dp grid from DESIGN_SYSTEM.md
class _SplashTokens {
  static const Color primaryOrange = Color(0xFFFF6600);
  static const Color softSaffron = Color(0xFFFF9E4F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1A1918);
  static const Color mutedText = Color(0xFF9F9B96);
  static const Color borderSubtle = Color(0xFFEAE8E3);

  // Animation durations
  static const Duration dInstant = Duration(milliseconds: 0);
  static const Duration dShort = Duration(milliseconds: 150);
  static const Duration dMedium = Duration(milliseconds: 250);
  static const Duration dLong = Duration(milliseconds: 400);
  static const Duration dEntrance = Duration(milliseconds: 900);
  static const Duration dPulse = Duration(milliseconds: 2400);
  static const Duration dFloat = Duration(milliseconds: 3000);
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _taglineCtrl;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoSlideY;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _progressAnim;

  // ── Particles ──────────────────────────────────────────────────────────────
  late final List<_FloatingOrb> _orbs;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
    _initOrbs();
    _initAnimations();
    _scheduleNavigation();
  }

  void _initOrbs() {
    final rng = math.Random(42);
    _orbs = List.generate(18, (_) => _FloatingOrb(rng));
  }

  void _initAnimations() {
    // 1. Entrance — logo scale + fade + slide up (900ms)
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _logoSlideY = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _ringScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _ringOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.55, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Tagline — delayed entrance after title
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut),
    );

    // 3. Ambient pulse — continuous breathe
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: _SplashTokens.dPulse,
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );

    // 4. Float — orb drift
    _floatCtrl = AnimationController(
      vsync: this,
      duration: _SplashTokens.dFloat,
    )..repeat();

    _floatAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_floatCtrl);

    // 5. Progress bar
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOutCubic),
    );

    // Start sequence
    _entranceCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _taglineCtrl.forward();
      });
    });
    _progressCtrl.forward();
  }

  void _scheduleNavigation() {
    // ── PRESERVED NAVIGATION LOGIC (DO NOT MODIFY) ────────────────────────
    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
        ref.read(splashShownProvider.notifier).setShown(true);
        final authState = ref.read(authProvider);
        if (authState is AuthAuthenticated) {
          final role = authState.userType.toLowerCase().trim();
          if (role == 'admin') {
            context.go('/admin-dashboard');
          } else if (role == 'businessowner' || role == 'client') {
            context.go('/business-dashboard');
          } else {
            context.go('/home');
          }
        } else {
          context.go('/welcome');
        }
      }
    });
    // ─────────────────────────────────────────────────────────────────────
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _progressCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _SplashTokens.white,
      body: Stack(
        children: [
          // ── Layer 1: Aurora Background Gradients ──────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _AuroraBackgroundPainter(),
            ),
          ),

          // ── Layer 2: Floating Orbs ─────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, __) => CustomPaint(
                painter: _OrbPainter(_orbs, _floatAnim.value),
              ),
            ),
          ),

          // ── Layer 3: Main Content ─────────────────────────────────────────
          SizedBox.expand(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // ── Logo Section ────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _entranceCtrl,
                    builder: (_, child) {
                      return Opacity(
                        opacity: _logoFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _logoSlideY.value),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _LogoStack(
                      pulseCtrl: _pulseCtrl,
                      pulseAnim: _pulseAnim,
                      ringScale: _ringScale,
                      ringOpacity: _ringOpacity,
                      entranceCtrl: _entranceCtrl,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Title ──────────────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _entranceCtrl,
                    builder: (_, child) {
                      return FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Vocal for Sanatan',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: _SplashTokens.charcoal,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Tagline with separate delayed fade
                        AnimatedBuilder(
                          animation: _taglineCtrl,
                          builder: (_, child) => Opacity(
                            opacity: _taglineFade.value,
                            child: child,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _SplashTokens.primaryOrange.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: _SplashTokens.primaryOrange.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Text(
                              'DISCOVER & SUPPORT LOCAL HERITAGE',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _SplashTokens.primaryOrange,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Progress Loader ────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (_, __) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sleek hairline progress bar
                            _HairlineProgress(progress: _progressAnim.value),
                            const SizedBox(height: 16),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: _SplashTokens.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: math.max(24, size.height * 0.04)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LOGO STACK: Concentric rings + shimmer + logo ───────────────────────────
class _LogoStack extends StatelessWidget {
  final AnimationController pulseCtrl;
  final Animation<double> pulseAnim;
  final Animation<double> ringScale;
  final Animation<double> ringOpacity;
  final AnimationController entranceCtrl;

  const _LogoStack({
    required this.pulseCtrl,
    required this.pulseAnim,
    required this.ringScale,
    required this.ringOpacity,
    required this.entranceCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Outer ambient ring (slow pulse) ─────────────────────────────
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) {
              return AnimatedBuilder(
                animation: entranceCtrl,
                builder: (_, child) => Opacity(
                  opacity: ringOpacity.value,
                  child: Transform.scale(
                    scale: ringScale.value * pulseAnim.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF6600).withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Mid ring ────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) {
              return AnimatedBuilder(
                animation: entranceCtrl,
                builder: (_, child) => Opacity(
                  opacity: ringOpacity.value * 0.7,
                  child: Transform.scale(
                    scale: ringScale.value * (0.85 + (pulseAnim.value - 0.92) * 0.5),
                    child: child,
                  ),
                ),
                child: Container(
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF9E4F).withValues(alpha: 0.14),
                      width: 1.0,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF6600).withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Inner glow halo ──────────────────────────────────────────────
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) => Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6600).withValues(alpha: 0.1 * pulseAnim.value),
                    blurRadius: 32 * pulseAnim.value,
                    spreadRadius: 4 * pulseAnim.value,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF9E4F).withValues(alpha: 0.06),
                    blurRadius: 56,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),

          // ── Logo Circle ──────────────────────────────────────────────────
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: _SplashTokens.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF6600).withValues(alpha: 0.12),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFFFF6600).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: ClipOval(
              child: Image.asset(
                'assets/images/splash_screen.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/splash_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      'ॐ',
                      style: TextStyle(
                        color: Color(0xFFFF6600),
                        fontSize: 58,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
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

// ─── HAIRLINE PROGRESS BAR ────────────────────────────────────────────────────
class _HairlineProgress extends StatelessWidget {
  final double progress;

  const _HairlineProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const double barWidth = 100.0;
        return SizedBox(
          width: barWidth,
          height: 2,
          child: Stack(
            children: [
              // Track
              Container(
                decoration: BoxDecoration(
                  color: _SplashTokens.borderSubtle,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF6600),
                        Color(0xFFFF9E4F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6600).withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── AURORA BACKGROUND PAINTER ────────────────────────────────────────────────
class _AuroraBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // White base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Top-left warm saffron glow
    _drawRadial(
      canvas,
      size,
      center: Offset(size.width * 0.1, size.height * 0.05),
      radius: size.width * 0.85,
      color: const Color(0xFFFF9E4F).withValues(alpha: 0.055),
    );

    // Bottom-right orange glow
    _drawRadial(
      canvas,
      size,
      center: Offset(size.width * 0.92, size.height * 0.92),
      radius: size.width * 0.8,
      color: const Color(0xFFFF6600).withValues(alpha: 0.038),
    );

    // Center subtle bloom
    _drawRadial(
      canvas,
      size,
      center: Offset(size.width * 0.5, size.height * 0.42),
      radius: size.width * 0.55,
      color: const Color(0xFFFF9E4F).withValues(alpha: 0.028),
    );
  }

  void _drawRadial(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── FLOATING ORB ─────────────────────────────────────────────────────────────
class _FloatingOrb {
  double x;
  double startY;
  double speed;
  double size;
  double opacity;
  double phase;

  _FloatingOrb(math.Random rng)
      : x = rng.nextDouble(),
        startY = rng.nextDouble(),
        speed = 0.15 + rng.nextDouble() * 0.25,
        size = 1.5 + rng.nextDouble() * 3.0,
        opacity = 0.04 + rng.nextDouble() * 0.14,
        phase = rng.nextDouble() * math.pi * 2;
}

class _OrbPainter extends CustomPainter {
  final List<_FloatingOrb> orbs;
  final double t;

  _OrbPainter(this.orbs, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final orb in orbs) {
      final yOffset = (t * orb.speed + orb.phase / (2 * math.pi)) % 1.0;
      final y = (orb.startY + yOffset) % 1.0;
      final opacity = orb.opacity * (0.5 + 0.5 * math.sin(t * math.pi * 2 + orb.phase));
      paint.color = const Color(0xFFFF6600).withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(orb.x * size.width, y * size.height),
        orb.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.t != t;
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  final List<Particle> _particles = List.generate(30, (index) => Particle());

  @override
  void initState() {
    super.initState();

    HapticFeedback.lightImpact();

    // 1. Entry Animation (Logo scale + fade)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // 2. Continuous Shimmer Sweep (subtle metallic shimmer)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );

    // 3. Ambient Breathing Pulse Aura
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 4. Progress Bar Fill
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _mainController.forward();
    _progressController.forward();

    // Navigation timer - keeps original logic completely untouched
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
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ─── 1. DYNAMIC AMBIENT PARTICLE ENGINE (Subtle saffron float) ───
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticleSystemPainter(_particles),
                );
              },
            ),
          ),

          // ─── 2. RADIAL AMBIENT BACKGROUND GLOW (Soft orange gradient accents) ───
          Positioned.fill(
            child: CustomPaint(
              painter: SplashBackgroundPainter(),
            ),
          ),

          // ─── 3. MAIN HERO LOGO & APP TITLES ───
          SizedBox.expand(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ambient Glowing Halo Container wrapping Logo
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6600).withOpacity(0.12 * _pulseAnimation.value),
                                    blurRadius: 40 * _pulseAnimation.value,
                                    spreadRadius: 8 * _pulseAnimation.value,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFFF9E4F).withOpacity(0.08),
                                    blurRadius: 70,
                                    spreadRadius: 12,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: const [
                                      Colors.white,
                                      Color(0xFFFF9E4F), // soft saffron sweep
                                      Colors.white,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                    begin: Alignment(_shimmerAnimation.value - 1, 0),
                                    end: Alignment(_shimmerAnimation.value, 0),
                                  ).createShader(bounds);
                                },
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFF6600).withOpacity(0.15),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/splash_screen.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/splash_logo.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Text(
                                                'ॐ',
                                                style: TextStyle(
                                                  color: Color(0xFFFF6600),
                                                  fontSize: 64,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Premium Typography Title Text
                        const Text(
                          'Vocal for Sanatan',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1918), // Charcoal High
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Premium Subtitle Tagline
                        Text(
                          'DISCOVER & SUPPORT LOCAL HERITAGE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF6600).withOpacity(0.85),
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ─── 4. MINIMAL LOADING INDICATOR & VERSION TEXT ───
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sleek micro-progress loader
                            Container(
                              height: 2,
                              width: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAE8E3), // color-border-subtle
                                borderRadius: BorderRadius.circular(1),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6600), // color-primary
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: const Color(0xFF1A1918).withOpacity(0.3),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AMBIENT FLOATING PARTICLE ENGINE ───
class Particle {
  late double x;
  late double y;
  late double speed;
  late double size;
  late double opacity;

  Particle() {
    reset();
  }

  void reset() {
    final rand = math.Random();
    x = rand.nextDouble();
    y = 1.0 + rand.nextDouble() * 0.2;
    speed = 0.0002 + rand.nextDouble() * 0.0006;
    size = 1.2 + rand.nextDouble() * 2.8;
    opacity = 0.08 + rand.nextDouble() * 0.32;
  }

  void update() {
    y -= speed;
    if (y < -0.1) {
      reset();
    }
  }
}

class ParticleSystemPainter extends CustomPainter {
  final List<Particle> particles;

  ParticleSystemPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      p.update();
      paint.color = const Color(0xFFFF6600).withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── SPLASH BACKGROUND PAINTER (Clean White with soft top-left/bottom-right glows) ───
class SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw main background
    canvas.drawRect(rect, Paint()..color = Colors.white);

    // Subtle top-left Saffron Glow
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9E4F).withOpacity(0.08), // soft saffron
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.8));
    canvas.drawRect(rect, p1);

    // Subtle bottom-right Orange Glow
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6600).withOpacity(0.04), // soft orange
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: size.width * 0.9));
    canvas.drawRect(rect, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

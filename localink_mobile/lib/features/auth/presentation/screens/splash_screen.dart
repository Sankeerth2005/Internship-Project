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
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  final List<Particle> _particles = List.generate(45, (index) => Particle());

  @override
  void initState() {
    super.initState();

    // Haptic feedback for luxury tactile feel
    HapticFeedback.lightImpact();

    // Set edge-to-edge transparent system bars for full screen immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 1. Entry Fade Animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // 2. Active Progress Bar Fill Animation (0% to 100%)
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

    _fadeController.forward();
    _progressController.forward();

    // Navigation timer to transition after splash sequence completes
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
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // ─── 1. FULL-SCREEN RESPONSIVE HERO DESIGN (ASSETS/IMAGES/SPLASH_SCREEN.PNG) ───
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Image.asset(
                  'assets/images/splash_screen.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 90,
                        color: Color(0xFFFF7A00),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ─── 2. DYNAMIC AMBIENT GOLD FLOATING PARTICLES OVERLAY ───
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticleSystemPainter(_particles),
                );
              },
            ),
          ),

          // ─── 3. LIVE GLOWING PROGRESS BAR OVERLAY AT BOTTOM ───
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 28,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.62,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E140A).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF9D00),
                                Color(0xFFFF6000),
                                Color(0xFFFF3D00),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF7A00).withValues(alpha: 0.9),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
    speed = 0.0003 + rand.nextDouble() * 0.0009;
    size = 1.0 + rand.nextDouble() * 2.8;
    opacity = 0.15 + rand.nextDouble() * 0.65;
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
      paint.color = const Color(0xFFFF9D00).withValues(alpha: p.opacity);
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

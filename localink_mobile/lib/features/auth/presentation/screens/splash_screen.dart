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

  final List<Particle> _particles = List.generate(35, (index) => Particle());

  @override
  void initState() {
    super.initState();

    // Haptic feedback for tactile luxury feel
    HapticFeedback.lightImpact();

    // 1. Entry Animation (Logo scale + fade)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );

    // 2. Continuous Shimmer Sweep (CRED style metallic light pass)
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

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 4. Progress Bar Fill (0% to 100%)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    );

    _mainController.forward();
    _progressController.forward();

    // Navigation timer
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
      backgroundColor: const Color(0xFF080706),
      body: Stack(
        children: [
          // ─── 1. DYNAMIC AMBIENT PARTICLE ENGINE (CRED / SLICE STYLED) ───
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

          // ─── 2. RADIAL AMBIENT BACKGROUND GLOW ───
          Positioned.fill(
            child: CustomPaint(
              painter: SplashBackgroundPainter(),
            ),
          ),

          // ─── 3. MAIN EMBLEM & HERO BRANDING BLOCK ───
          SizedBox.expand(
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
                      // Glowing Outer Ring Aura
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 155,
                            height: 155,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7A00).withValues(alpha: 0.3 * _pulseAnimation.value),
                                  blurRadius: 50 * _pulseAnimation.value,
                                  spreadRadius: 8 * _pulseAnimation.value,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFF4500).withValues(alpha: 0.2),
                                  blurRadius: 80,
                                  spreadRadius: 15,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: ClipOval(
                          child: Container(
                            width: 145,
                            height: 145,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF7A00),
                                  const Color(0xFFFF3D00).withValues(alpha: 0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ClipOval(
                              child: Container(
                                color: const Color(0xFF100E0D),
                                child: _buildSplashImageOrVector(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Metallic Shimmer Title Text
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: const [
                                  Colors.white,
                                  Color(0xFFFFD700), // Gold highlight pass
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                begin: Alignment(_shimmerAnimation.value - 1, 0),
                                end: Alignment(_shimmerAnimation.value, 0),
                              ).createShader(bounds);
                            },
                            child: const Text(
                              'VOCAL FOR SANATAN',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 3.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      // Premium Subtitle Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'DISCOVER & SUPPORT LOCAL HERITAGE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.9),
                            letterSpacing: 1.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ─── 4. CRED-STYLE FUTURISTIC LOADER & PERCENTAGE COUNTER ───
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    final percent = (_progressAnimation.value * 100).toInt();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                percent < 100 ? 'INITIALIZING APPLICATION...' : 'READY',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: const TextStyle(
                                  color: Color(0xFFFF7A00),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Custom Glowing Progress Bar
                          Container(
                            height: 3,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF7A00), Color(0xFFFF3D00)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF7A00).withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 45),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Checks if custom user uploaded splash image asset is present, else falls back to vector
  Widget _buildSplashImageOrVector() {
    return Image.asset(
      'assets/images/splash_logo.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              painter: SplashEmblemPainter(),
            );
          },
        );
      },
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
    speed = 0.0003 + rand.nextDouble() * 0.0008;
    size = 1.5 + rand.nextDouble() * 3.5;
    opacity = 0.15 + rand.nextDouble() * 0.55;
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
      paint.color = const Color(0xFFFF7A00).withValues(alpha: p.opacity);
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

// ─── SPLASH BACKGROUND PAINTER ───
class SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF070605),
          const Color(0xFF0F0C0A),
          const Color(0xFF330E00),
          const Color(0xFF7A2000),
        ],
        stops: const [0.0, 0.45, 0.85, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1.0;

    double spacing = 14.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── VECTOR FALLBACK EMBLEM PAINTER ───
class SplashEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    final paint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, paint);

    final rayPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (int i = 0; i < 24; i++) {
      double angle = (i * 360 / 24) * math.pi / 180;
      Offset p1 = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      Offset p2 = Offset(center.dx + (radius + 5) * math.cos(angle), center.dy + (radius + 5) * math.sin(angle));
      canvas.drawLine(p1, p2, rayPaint);
    }

    final flagPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.fill;

    final flagPath = Path();
    double poleX = center.dx - 8;
    double topY = center.dy - radius + 10;
    double bottomY = center.dy + radius - 10;
    double clothTopY = center.dy - radius + 12;
    double clothBottomY = center.dy + 6;
    double tipX = center.dx + radius - 6;

    flagPath.moveTo(poleX, topY);
    flagPath.lineTo(poleX, bottomY);

    flagPath.moveTo(poleX, clothTopY);
    flagPath.lineTo(tipX, (clothTopY + clothBottomY) / 2);
    flagPath.lineTo(poleX, clothBottomY);
    flagPath.close();

    canvas.drawPath(flagPath, flagPaint);

    final poleLinePaint = Paint()
      ..color = const Color(0xFF0C0C0C)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(poleX, topY), Offset(poleX, bottomY), poleLinePaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ॐ',
        style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double clothCenterX = poleX + ((tipX - poleX) * 0.33);
    double clothCenterY = (clothTopY + clothBottomY) / 2;

    textPainter.paint(
      canvas,
      Offset(clothCenterX - (textPainter.width / 2), clothCenterY - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';

import '../widgets/splash/background_gradient.dart';
import '../widgets/splash/temple_background.dart';
import '../widgets/splash/sunrise_glow.dart';
import '../widgets/splash/energy_waves.dart';
import '../widgets/splash/floating_particles.dart';
import '../widgets/splash/animated_logo.dart';
import '../widgets/splash/app_title.dart';
import '../widgets/splash/loading_bar.dart';

/// Premium Animated Splash Screen orchestrating 11 independent modular layers
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ─── ANIMATION CONTROLLERS ───
  late AnimationController _ambientController;
  late AnimationController _templeController;
  late AnimationController _logoScaleController;
  late AnimationController _ringRotationController;
  late AnimationController _glowPulseController;
  late AnimationController _flagWaveController;
  late AnimationController _omPulseController;
  late AnimationController _particleController;
  late AnimationController _energyWaveController;
  late AnimationController _titleEntranceController;
  late AnimationController _taglineEntranceController;
  late AnimationController _loadingBarController;

  // ─── TWEENS & ANIMATIONS ───
  late Animation<double> _ambientAnimation;
  late Animation<double> _templeOpacityAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _ringRotationAnimation;
  late Animation<double> _glowPulseAnimation;
  late Animation<double> _flagWaveAnimation;
  late Animation<double> _omScaleAnimation;
  late Animation<Color?> _omGlowColorAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _energyWaveAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _titleTranslateAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<double> _taglineTranslateAnimation;
  late Animation<double> _loadingProgressAnimation;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // 1. Layer 1 & 3: Background Ambient Glow (5s loop forever, 40% -> 60% -> 40%)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _ambientAnimation = Tween<double>(begin: 0.40, end: 0.60).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );
    _ambientController.repeat(reverse: true);

    // 2. Layer 2: Temple Silhouette Fade In (0% -> 35% in 1500ms)
    _templeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _templeOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _templeController, curve: Curves.easeOut),
    );

    // 3. Layer 6/7/8: Logo Scale (0.75 -> 1.05 -> 1.00 in 800ms, easeOutBack)
    _logoScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.75, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.00)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_logoScaleController);

    // 4. Layer 6: Ring Rotation (360° in 20s, Linear, Infinite)
    _ringRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _ringRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringRotationController, curve: Curves.linear),
    );
    _ringRotationController.repeat();

    // 5. Layer 5/6: Glow Behind Logo (Blur radius 20 -> 45 -> 20 every 2s)
    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowPulseAnimation = Tween<double>(begin: 20.0, end: 45.0).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );
    _glowPulseController.repeat(reverse: true);

    // 6. Layer 7: Flag Waving (-3° -> 3° -> -3° in 2.5s)
    _flagWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _flagWaveAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _flagWaveController, curve: Curves.easeInOut),
    );
    _flagWaveController.repeat(reverse: true);

    // 7. Layer 8: Om Symbol Scale & Glow Color (1.0 -> 1.08 -> 1.0 in 2s)
    _omPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _omScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _omPulseController, curve: Curves.easeInOut),
    );
    _omGlowColorAnimation = ColorTween(
      begin: const Color(0xFFFF8C00),
      end: const Color(0xFFFFC857),
    ).animate(
      CurvedAnimation(parent: _omPulseController, curve: Curves.easeInOut),
    );
    _omPulseController.repeat(reverse: true);

    // 8. Layer 5: Floating Particles (Slow continuous upward rise)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );
    _particleController.repeat();

    // 9. Layer 4: Energy Waves (Slow horizontal sway)
    _energyWaveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _energyWaveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _energyWaveController, curve: Curves.easeInOut),
    );
    _energyWaveController.repeat(reverse: true);

    // 10. Layer 9: Title Entrance (Fade 0->1, Y 30->0 in 800ms, easeOutCubic)
    _titleEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleEntranceController, curve: Curves.easeOutCubic),
    );
    _titleTranslateAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _titleEntranceController, curve: Curves.easeOutCubic),
    );

    // 11. Layer 10: Tagline Entrance (Fade 0->1, Y 20->0 in 800ms, 300ms delay)
    _taglineEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineEntranceController, curve: Curves.easeOutCubic),
    );
    _taglineTranslateAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _taglineEntranceController, curve: Curves.easeOutCubic),
    );

    // 12. Layer 11: Loading Indicator Line (0.0 -> 1.0 in 1 second)
    _loadingBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadingProgressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingBarController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() {
    _templeController.forward();
    _logoScaleController.forward();

    // Timed entrance sequence
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) _titleEntranceController.forward();
    });

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) _taglineEntranceController.forward();
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _loadingBarController.forward().then((_) {
          _onLoadingCompleted();
        });
      }
    });
  }

  void _onLoadingCompleted() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    // Small breathing pause before seamless transition
    Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      ref.read(splashShownProvider.notifier).setShown(true);
      final authState = ref.read(authProvider);

      String nextRoute = '/welcome';
      if (authState is AuthAuthenticated) {
        final role = authState.userType.toLowerCase().trim();
        if (role == 'admin') {
          nextRoute = '/admin-dashboard';
        } else if (role == 'businessowner' || role == 'client') {
          nextRoute = '/business-dashboard';
        } else {
          nextRoute = '/home';
        }
      }

      context.go(nextRoute);
    });
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _templeController.dispose();
    _logoScaleController.dispose();
    _ringRotationController.dispose();
    _glowPulseController.dispose();
    _flagWaveController.dispose();
    _omPulseController.dispose();
    _particleController.dispose();
    _energyWaveController.dispose();
    _titleEntranceController.dispose();
    _taglineEntranceController.dispose();
    _loadingBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: Background Gradient & Ambient Radial Glow
            BackgroundGradient(ambientAnimation: _ambientAnimation),

            // Layer 2: Temple Silhouette Background
            TempleBackground(templeOpacityAnimation: _templeOpacityAnimation),

            // Layer 3: Bottom Sunrise Horizon Glow
            SunriseGlow(ambientAnimation: _ambientAnimation),

            // Layer 4: Animated Decorative Energy Waves
            EnergyWaves(waveAnimation: _energyWaveAnimation),

            // Layer 5: Floating Glowing Particles
            FloatingParticles(particleAnimation: _particleAnimation),

            // Layer 6, 7, 8 & Glow: Animated Logo Assembly
            Positioned(
              top: MediaQuery.of(context).size.height * 0.28,
              child: AnimatedLogo(
                logoScaleAnimation: _logoScaleAnimation,
                ringRotationAnimation: _ringRotationAnimation,
                glowPulseAnimation: _glowPulseAnimation,
                flagWaveAnimation: _flagWaveAnimation,
                omScaleAnimation: _omScaleAnimation,
                omGlowColorAnimation: _omGlowColorAnimation,
                size: 180.0,
              ),
            ),

            // Layer 9 & 10: Title & Tagline Block
            Positioned(
              top: MediaQuery.of(context).size.height * 0.55,
              left: 20,
              right: 20,
              child: AppTitle(
                titleFadeAnimation: _titleFadeAnimation,
                titleTranslateAnimation: _titleTranslateAnimation,
                taglineFadeAnimation: _taglineFadeAnimation,
                taglineTranslateAnimation: _taglineTranslateAnimation,
              ),
            ),

            // Layer 11: Loading Progress Line
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 50,
              child: LoadingBar(
                progressAnimation: _loadingProgressAnimation,
                width: 160.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

// ─── DESIGN TOKENS ────────────────────────────────────────────────────────────
// Aligned to DESIGN_SYSTEM.md — no hardcoded colors outside this block
class _Token {
  static const Color primary = Color(0xFFFF6600);
  static const Color white = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1A1918);
  static const Color mediumText = Color(0xFF5F5C58);
  static const Color mutedText = Color(0xFF9F9B96);
  static const Color surface = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);

  // Spacing (4dp grid)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Radii
  static const double radiusSm = 8;
  static const double radiusLg = 16;
  static const double radiusRound = 999;
}

// ─── DATA: Onboarding slide content ───────────────────────────────────────────
class _SlideData {
  final String headline;
  final String description;
  final String eyebrow;
  final Widget illustration;
  final Color accentHue;

  const _SlideData({
    required this.headline,
    required this.description,
    required this.eyebrow,
    required this.illustration,
    required this.accentHue,
  });
}

// ─── MAIN WIDGET ──────────────────────────────────────────────────────────────
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showRoleSelection = false;
  String _selectedRole = 'user';
  bool _showAdmin = false;
  int _logoTapCount = 0;
  Timer? _logoTapTimer;

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _slideEntryCtrl;
  late final AnimationController _roleEntryCtrl;
  late final AnimationController _illustrationCtrl;

  late final Animation<double> _slideContentFade;
  late final Animation<Offset> _slideContentOffset;
  late final Animation<double> _roleEntryFade;
  late final Animation<Offset> _roleEntrySlide;
  late final Animation<double> _illustrationScale;
  late final Animation<double> _illustrationFade;

  // ── Slides ─────────────────────────────────────────────────────────────────
  late final List<_SlideData> _slides;

  @override
  void initState() {
    super.initState();
    _initSlides();
    _initAnimations();
  }

  void _initSlides() {
    _slides = const [
      _SlideData(
        eyebrow: 'DISCOVERY',
        headline: 'Discover\nLocal Trust',
        description:
            'Connect with verified local businesses, organizations, and professionals in your neighborhood — backed by personal owner accountability.',
        illustration: DiscoveryIllustration(),
        accentHue: Color(0xFFFF6600),
      ),
      _SlideData(
        eyebrow: 'COMMUNICATION',
        headline: 'Direct and\nFee-Free',
        description:
            'Get turn-by-turn directions and call owners directly with zero middleman commissions or hidden transaction costs.',
        illustration: DirectCommunicationIllustration(),
        accentHue: Color(0xFFFF8833),
      ),
      _SlideData(
        eyebrow: 'AI ASSISTANT',
        headline: 'Meet Your\nAI Local Guide',
        description:
            'Search using natural voice commands or chat with our Llama-powered AI assistant to get instant recommendations as interactive cards.',
        illustration: AiAssistantIllustration(),
        accentHue: Color(0xFFFF9E4F),
      ),
      _SlideData(
        eyebrow: 'COMMUNITY',
        headline: 'Empower Your\nCommunity',
        description:
            'Save favorites, share local discoveries, request new listings, and directly submit feedback to improve your neighborhood.',
        illustration: CommunitySupportIllustration(),
        accentHue: Color(0xFFFF6600),
      ),
    ];
  }

  void _initAnimations() {
    // Slide content entrance
    _slideEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _slideContentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideEntryCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideContentOffset = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideEntryCtrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Illustration
    _illustrationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _illustrationScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _illustrationCtrl, curve: Curves.easeOutBack),
    );
    _illustrationFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _illustrationCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    // Role selection entrance
    _roleEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _roleEntryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _roleEntryCtrl, curve: Curves.easeOut),
    );
    _roleEntrySlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _roleEntryCtrl, curve: Curves.easeOutCubic),
    );

    // Start initial entrance
    _slideEntryCtrl.forward();
    _illustrationCtrl.forward();
  }

  void _playPageTransition() {
    _slideEntryCtrl.reset();
    _illustrationCtrl.reset();
    _slideEntryCtrl.forward();
    _illustrationCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoTapTimer?.cancel();
    _slideEntryCtrl.dispose();
    _roleEntryCtrl.dispose();
    _illustrationCtrl.dispose();
    super.dispose();
  }

  // ── PRESERVED LOGIC (DO NOT MODIFY) ────────────────────────────────────────
  void _onLogoTap() {
    _logoTapCount++;
    _logoTapTimer?.cancel();
    _logoTapTimer = Timer(const Duration(milliseconds: 600), () {
      _logoTapCount = 0;
    });

    if (_logoTapCount == 3) {
      setState(() {
        _showAdmin = !_showAdmin;
        if (!_showAdmin && _selectedRole == 'admin') {
          _selectedRole = 'user';
        }
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moderator access options updated.'),
          duration: Duration(seconds: 1),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      _logoTapCount = 0;
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _roleEntryCtrl.reset();
    setState(() => _showRoleSelection = true);
    _roleEntryCtrl.forward();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _roleEntryCtrl.reset();
      setState(() => _showRoleSelection = true);
      _roleEntryCtrl.forward();
    }
  }
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Token.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _showRoleSelection
            ? _RoleSelectionView(
                key: const ValueKey('role_selection'),
                selectedRole: _selectedRole,
                showAdmin: _showAdmin,
                fadeAnim: _roleEntryFade,
                slideAnim: _roleEntrySlide,
                onLogoTap: _onLogoTap,
                onRoleChanged: (role) => setState(() => _selectedRole = role),
                onContinue: () {
                  HapticFeedback.lightImpact();
                  context.go('/login', extra: _selectedRole);
                },
                onSignup: () {
                  HapticFeedback.lightImpact();
                  context.go('/signup', extra: _selectedRole);
                },
                onExplore: () {
                  HapticFeedback.lightImpact();
                  context.go('/home');
                },
              )
            : _OnboardingView(
                key: const ValueKey('onboarding'),
                slides: _slides,
                currentPage: _currentPage,
                pageController: _pageController,
                contentFade: _slideContentFade,
                contentOffset: _slideContentOffset,
                illustrationScale: _illustrationScale,
                illustrationFade: _illustrationFade,
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  _playPageTransition();
                },
                onSkip: _skipOnboarding,
                onNext: _nextPage,
              ),
      ),
    );
  }
}

// ─── ONBOARDING VIEW ──────────────────────────────────────────────────────────
class _OnboardingView extends StatelessWidget {
  final List<_SlideData> slides;
  final int currentPage;
  final PageController pageController;
  final Animation<double> contentFade;
  final Animation<Offset> contentOffset;
  final Animation<double> illustrationScale;
  final Animation<double> illustrationFade;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _OnboardingView({
    super.key,
    required this.slides,
    required this.currentPage,
    required this.pageController,
    required this.contentFade,
    required this.contentOffset,
    required this.illustrationScale,
    required this.illustrationFade,
    required this.onPageChanged,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final slide = slides[currentPage];
    final isLast = currentPage == slides.length - 1;
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // ── Soft background bloom per slide ─────────────────────────────────
        Positioned.fill(
          child: CustomPaint(
            painter: _SlideBackgroundPainter(slideIndex: currentPage),
          ),
        ),

        SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  _Token.lg,
                  _Token.sm,
                  _Token.md,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand wordmark
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primarySolarGradient,
                          ),
                          child: const Center(
                            child: Text(
                              'ॐ',
                              style: TextStyle(
                                color: _Token.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: _Token.sm),
                        Text(
                          'Vocal for Sanatan',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _Token.charcoal,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),

                    // Skip button
                    Semantics(
                      button: true,
                      label: 'Skip onboarding',
                      child: TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          foregroundColor: _Token.mutedText,
                          padding: const EdgeInsets.symmetric(
                            horizontal: _Token.md,
                            vertical: _Token.sm,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _Token.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Illustration area ─────────────────────────────────────────
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: pageController,
                  onPageChanged: onPageChanged,
                  itemCount: slides.length,
                  itemBuilder: (_, index) {
                    return AnimatedBuilder(
                      animation: Listenable.merge(
                          [illustrationScale, illustrationFade]),
                      builder: (_, child) {
                        final isActive = index == currentPage;
                        return Opacity(
                          opacity: isActive ? illustrationFade.value : 1.0,
                          child: Transform.scale(
                            scale: isActive ? illustrationScale.value : 1.0,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _Token.xxl,
                          vertical: _Token.lg,
                        ),
                        child: _IllustrationCard(
                          slide: slides[index],
                          size: size,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Text content ──────────────────────────────────────────────
              Expanded(
                flex: 4,
                child: AnimatedBuilder(
                  animation: Listenable.merge([contentFade, contentOffset]),
                  builder: (_, child) => FadeTransition(
                    opacity: contentFade,
                    child: SlideTransition(
                      position: contentOffset,
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _Token.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Eyebrow label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _Token.md,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: slide.accentHue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(_Token.radiusRound),
                          ),
                          child: Text(
                            slide.eyebrow,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: slide.accentHue,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: _Token.md),

                        // Headline
                        Text(
                          slide.headline,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _Token.charcoal,
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: _Token.md),

                        // Description
                        Text(
                          slide.description,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            height: 1.55,
                            color: _Token.mediumText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom: dots + button ─────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _Token.xl,
                  _Token.lg,
                  _Token.xl,
                  math.max(bottomPad + _Token.lg, _Token.xxl),
                ),
                child: Row(
                  children: [
                    // Page dots
                    Row(
                      children: List.generate(slides.length, (i) {
                        final active = i == currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubic,
                          margin: const EdgeInsets.only(right: _Token.sm),
                          width: active ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: active ? _Token.primary : _Token.border,
                            borderRadius:
                                BorderRadius.circular(_Token.radiusRound),
                          ),
                        );
                      }),
                    ),

                    const Spacer(),

                    // CTA Button
                    Semantics(
                      button: true,
                      label: isLast
                          ? 'Get started with the app'
                          : 'Continue to next onboarding slide',
                      child: _PressableButton(
                        onPressed: onNext,
                        label: isLast ? 'Get Started' : 'Continue',
                        isLast: isLast,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── ILLUSTRATION CARD ────────────────────────────────────────────────────────
class _IllustrationCard extends StatelessWidget {
  final _SlideData slide;
  final Size size;

  const _IllustrationCard({required this.slide, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Token.surface,
        borderRadius: BorderRadius.circular(_Token.radiusLg * 1.5),
        border: Border.all(color: _Token.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: slide.accentHue.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_Token.radiusLg * 1.5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle gradient backdrop inside card
            Positioned.fill(
              child: CustomPaint(
                painter: _CardBackgroundPainter(accentHue: slide.accentHue),
              ),
            ),
            // The illustration
            Padding(
              padding: const EdgeInsets.all(_Token.xl),
              child: slide.illustration,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PRESSABLE BUTTON ─────────────────────────────────────────────────────────
class _PressableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isLast;

  const _PressableButton({
    required this.onPressed,
    required this.label,
    required this.isLast,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (_, child) => Transform.scale(
          scale: _pressScale.value,
          child: child,
        ),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: _Token.xl),
          decoration: BoxDecoration(
            gradient: AppTheme.primarySolarGradient,
            borderRadius: BorderRadius.circular(_Token.radiusRound),
            boxShadow: [
              BoxShadow(
                color: _Token.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _Token.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: _Token.sm),
              Icon(
                widget.isLast
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_rounded,
                size: 16,
                color: _Token.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ROLE SELECTION VIEW ──────────────────────────────────────────────────────
// Phase 2.2: Premium hero section + full-width large role cards
class _RoleSelectionView extends StatefulWidget {
  final String selectedRole;
  final bool showAdmin;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback onLogoTap;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onContinue;
  final VoidCallback onSignup;
  final VoidCallback onExplore;

  const _RoleSelectionView({
    super.key,
    required this.selectedRole,
    required this.showAdmin,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onLogoTap,
    required this.onRoleChanged,
    required this.onContinue,
    required this.onSignup,
    required this.onExplore,
  });

  @override
  State<_RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<_RoleSelectionView>
    with TickerProviderStateMixin {
  late final AnimationController _cardEntryCtrl;
  late final List<Animation<double>> _cardFades;
  late final List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _cardEntryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Stagger each card by 80ms
    _cardFades = List.generate(2, (i) {
      final start = 0.1 + i * 0.18;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _cardEntryCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _cardSlides = List.generate(2, (i) {
      final start = 0.1 + i * 0.18;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _cardEntryCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _cardEntryCtrl.forward();
  }

  @override
  void dispose() {
    _cardEntryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: CustomPaint(painter: _RoleBackgroundPainter()),
        ),

        Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: FadeTransition(
                  opacity: widget.fadeAnim,
                  child: SlideTransition(
                    position: widget.slideAnim,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        _Token.xl,
                        _Token.lg,
                        _Token.xl,
                        _Token.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── Top row: skip link ──────────────────────────
                          Align(
                            alignment: Alignment.topRight,
                            child: Semantics(
                              button: true,
                              label: 'Skip login and explore the app',
                              child: TextButton(
                                onPressed: widget.onExplore,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 44),
                                  foregroundColor: _Token.mediumText,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: _Token.sm,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Explore',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: _Token.mediumText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: _Token.xs),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: _Token.mutedText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: _Token.lg),

                          // ── Hero section ─────────────────────────────────
                          _buildHeroSection(context),

                          const SizedBox(height: _Token.xxl),

                          // ── Large role cards ──────────────────────────────
                          _buildRoleCards(),

                          // Admin card (hidden gateway)
                          if (widget.showAdmin) ...
                            _buildAdminCard(),

                          const SizedBox(height: _Token.xl),

                          // ── Trust indicators ──────────────────────────────
                          _buildTrustRow(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Sticky bottom CTA bar ─────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                _Token.xl,
                _Token.lg,
                _Token.xl,
                math.max(bottomPad + _Token.lg, _Token.xl),
              ),
              decoration: BoxDecoration(
                color: _Token.white,
                border: Border(
                  top: BorderSide(color: _Token.border),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    button: true,
                    label: widget.selectedRole == 'admin'
                        ? 'Login as moderator admin'
                        : 'Continue to login screen',
                    child: _FullWidthButton(
                      onPressed: widget.onContinue,
                      label: widget.selectedRole == 'admin'
                          ? 'Login as Admin'
                          : 'Continue',
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ),

                  if (widget.selectedRole != 'admin') ...[
                    const SizedBox(height: _Token.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New here?  ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: _Token.mediumText,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onSignup,
                          child: Text(
                            'Create an Account',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _Token.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Hero section ────────────────────────────────────────────────────────────
  Widget _buildHeroSection(BuildContext context) {
    return Column(
      children: [
        // Logo with admin gateway
        GestureDetector(
          onTap: widget.onLogoTap,
          behavior: HitTestBehavior.opaque,
          child: Hero(
            tag: 'app_logo',
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primarySolarGradient,
                  boxShadow: [
                    BoxShadow(
                      color: _Token.primary.withValues(alpha: 0.26),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF9E4F).withValues(alpha: 0.14),
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: _Token.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'ॐ',
                      style: TextStyle(
                        color: _Token.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: _Token.xl),

        // Eyebrow
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _Token.md,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _Token.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(_Token.radiusRound),
            border: Border.all(
              color: _Token.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            'VOCAL FOR SANATAN',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _Token.primary,
              letterSpacing: 1.8,
            ),
          ),
        ),

        const SizedBox(height: _Token.md),

        // Main headline
        Text(
          'How will you\nuse the app?',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: _Token.charcoal,
                height: 1.15,
                letterSpacing: -0.6,
              ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: _Token.md),

        // Subtitle
        Text(
          'Choose your profile to get a personalised\nexperience built around your needs.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.55,
            color: _Token.mediumText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Large role cards ─────────────────────────────────────────────────────────
  Widget _buildRoleCards() {
    final cards = [
      _LargeRoleCardData(
        roleKey: 'user',
        title: 'Consumer',
        tagline: 'Discover & connect with local businesses',
        icon: Icons.person_rounded,
        benefits: const [
          'Search & discover verified local businesses',
          'AI voice search & smart recommendations',
          'Save favourites & share discoveries',
        ],
        accentColor: _Token.primary,
      ),
      _LargeRoleCardData(
        roleKey: 'businessowner',
        title: 'Business Owner',
        tagline: 'List your store and grow your customer base',
        icon: Icons.storefront_rounded,
        benefits: const [
          'List & promote your store 100% free',
          'Manage hours, photos & location',
          'Receive leads, views & verified ratings',
        ],
        accentColor: _Token.primary,
      ),
    ];

    return Column(
      children: List.generate(cards.length, (i) {
        final card = cards[i];
        return FadeTransition(
          opacity: i < _cardFades.length ? _cardFades[i] : const AlwaysStoppedAnimation(1.0),
          child: SlideTransition(
            position: i < _cardSlides.length
                ? _cardSlides[i]
                : const AlwaysStoppedAnimation(Offset.zero),
            child: Padding(
              padding: const EdgeInsets.only(bottom: _Token.md),
              child: _LargeRoleCard(
                data: card,
                isSelected: widget.selectedRole == card.roleKey,
                onTap: () => widget.onRoleChanged(card.roleKey),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Admin card (hidden gateway) ──────────────────────────────────────────────
  List<Widget> _buildAdminCard() {
    return [
      FadeTransition(
        opacity: widget.fadeAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: _Token.md),
          child: _LargeRoleCard(
            data: _LargeRoleCardData(
              roleKey: 'admin',
              title: 'Platform Admin',
              tagline: 'Governance, moderation & platform control',
              icon: Icons.admin_panel_settings_rounded,
              benefits: const [
                'Review & approve business listings',
                'Manage categories & system reports',
                'Full platform governance & user control',
              ],
              accentColor: const Color(0xFF5F5C58),
            ),
            isSelected: widget.selectedRole == 'admin',
            onTap: () => widget.onRoleChanged('admin'),
          ),
        ),
      ),
    ];
  }

  // ── Trust row ────────────────────────────────────────────────────────────────
  Widget _buildTrustRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TrustChip(icon: Icons.verified_rounded, label: 'Verified'),
        const SizedBox(width: _Token.sm),
        _TrustChip(icon: Icons.lock_outline_rounded, label: 'Secure'),
        const SizedBox(width: _Token.sm),
        _TrustChip(icon: Icons.favorite_rounded, label: 'Community'),
      ],
    );
  }
}

// ─── LARGE ROLE CARD DATA ─────────────────────────────────────────────────────
class _LargeRoleCardData {
  final String roleKey;
  final String title;
  final String tagline;
  final IconData icon;
  final List<String> benefits;
  final Color accentColor;

  const _LargeRoleCardData({
    required this.roleKey,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.benefits,
    required this.accentColor,
  });
}

// ─── LARGE ROLE CARD ─────────────────────────────────────────────────────────
class _LargeRoleCard extends StatefulWidget {
  final _LargeRoleCardData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _LargeRoleCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LargeRoleCard> createState() => _LargeRoleCardState();
}

class _LargeRoleCardState extends State<_LargeRoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;
    final accent = widget.data.accentColor;

    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) {
        _tapCtrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _tapScale,
        builder: (_, child) =>
            Transform.scale(scale: _tapScale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(_Token.xl),
          decoration: BoxDecoration(
            color: sel
                ? accent.withValues(alpha: 0.04)
                : _Token.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: sel ? accent : _Token.border,
              width: sel ? 2.0 : 1.0,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: icon + title + checkmark ─────────────────────
              Row(
                children: [
                  // Icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: sel ? accent : _Token.surface,
                      borderRadius: BorderRadius.circular(_Token.radiusSm + 4),
                      border: Border.all(
                        color: sel
                            ? accent.withValues(alpha: 0.3)
                            : _Token.border,
                      ),
                    ),
                    child: Icon(
                      widget.data.icon,
                      size: 26,
                      color: sel ? _Token.white : _Token.mediumText,
                    ),
                  ),

                  const SizedBox(width: _Token.md),

                  // Title + tagline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: sel ? accent : _Token.charcoal,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.data.tagline,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: _Token.mediumText,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: _Token.sm),

                  // Selection checkmark
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel ? accent : Colors.transparent,
                      border: Border.all(
                        color: sel ? accent : _Token.border,
                        width: sel ? 0 : 1.5,
                      ),
                    ),
                    child: sel
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: _Token.white,
                          )
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: _Token.lg),

              // ── Divider ───────────────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 1,
                color: sel
                    ? accent.withValues(alpha: 0.15)
                    : _Token.border,
              ),

              const SizedBox(height: _Token.lg),

              // ── Benefit list ──────────────────────────────────────────
              ...widget.data.benefits.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: _Token.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: sel
                                ? accent.withValues(alpha: 0.12)
                                : _Token.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: sel ? accent : _Token.mutedText,
                          ),
                        ),
                        const SizedBox(width: _Token.sm),
                        Expanded(
                          child: Text(
                            b,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              height: 1.5,
                              color: sel
                                  ? _Token.charcoal
                                  : _Token.mediumText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TRUST CHIP ───────────────────────────────────────────────────────────────
class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Token.md,
        vertical: _Token.xs + 2,
      ),
      decoration: BoxDecoration(
        color: _Token.surface,
        borderRadius: BorderRadius.circular(_Token.radiusRound),
        border: Border.all(color: _Token.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _Token.mutedText),
          const SizedBox(width: _Token.xs),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _Token.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ROLE CARD (legacy compact — kept for backward compat, unused in Phase 2.2+)
// The new premium large card is _LargeRoleCard above.
class _RoleCard extends StatefulWidget {
  final String roleKey;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  const _RoleCard({
    required this.roleKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) {
        _tapCtrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _tapScale,
        builder: (_, child) => Transform.scale(
          scale: _tapScale.value,
          child: child,
        ),
        child: SizedBox(
          width: widget.width,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              vertical: _Token.lg,
              horizontal: _Token.md,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? _Token.primary.withValues(alpha: 0.06)
                  : _Token.surface,
              borderRadius: BorderRadius.circular(_Token.radiusLg),
              border: Border.all(
                color:
                    widget.isSelected ? _Token.primary : _Token.border,
                width: widget.isSelected ? 2.0 : 1.0,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: _Token.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isSelected
                          ? _Token.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.isSelected
                            ? _Token.primary
                            : _Token.border,
                        width: 1.5,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: _Token.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: _Token.sm),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(_Token.md),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected ? _Token.primary : _Token.white,
                    border: Border.all(
                      color: widget.isSelected
                          ? _Token.primary
                          : _Token.border,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 22,
                    color: widget.isSelected ? _Token.white : _Token.mediumText,
                  ),
                ),
                const SizedBox(height: _Token.sm),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.isSelected ? _Token.primary : _Token.charcoal,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: _Token.xs),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: _Token.mutedText,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─── FULL-WIDTH BUTTON ────────────────────────────────────────────────────────
class _FullWidthButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const _FullWidthButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  State<_FullWidthButton> createState() => _FullWidthButtonState();
}

class _FullWidthButtonState extends State<_FullWidthButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
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
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.primarySolarGradient,
            borderRadius: BorderRadius.circular(_Token.radiusRound),
            boxShadow: [
              BoxShadow(
                color: _Token.primary.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _Token.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: _Token.sm),
              Icon(widget.icon, size: 18, color: _Token.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BACKGROUND PAINTERS ──────────────────────────────────────────────────────
class _SlideBackgroundPainter extends CustomPainter {
  final int slideIndex;

  _SlideBackgroundPainter({required this.slideIndex});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Soft top-right bloom
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9E4F).withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width, 0),
          radius: size.width * 0.8,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p1);

    // Bottom-left secondary bloom
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF6600).withValues(alpha: 0.03),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(0, size.height),
          radius: size.width * 0.7,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p2);
  }

  @override
  bool shouldRepaint(covariant _SlideBackgroundPainter old) =>
      old.slideIndex != slideIndex;
}

class _RoleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    final p = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9E4F).withValues(alpha: 0.045),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.12),
          radius: size.width * 0.75,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CardBackgroundPainter extends CustomPainter {
  final Color accentHue;

  _CardBackgroundPainter({required this.accentHue});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..shader = RadialGradient(
        colors: [
          accentHue.withValues(alpha: 0.055),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.4),
          radius: size.width * 0.6,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);
  }

  @override
  bool shouldRepaint(covariant _CardBackgroundPainter old) =>
      old.accentHue != accentHue;
}

// ─── ILLUSTRATIONS ────────────────────────────────────────────────────────────
// Preserved and refined from original implementation

class DiscoveryIllustration extends StatelessWidget {
  const DiscoveryIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _DiscoveryPainter(),
    );
  }
}

class _DiscoveryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Ambient circle
    canvas.drawCircle(
      center,
      w * 0.44,
      Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );

    // Concentric rings
    final ringPaint = Paint()
      ..color = const Color(0xFFFF9E4F).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, w * 0.30, ringPaint);
    canvas.drawCircle(center, w * 0.42, ringPaint..color = const Color(0xFFFF9E4F).withValues(alpha: 0.09));

    // Connecting lines
    final linePaint = Paint()
      ..color = const Color(0xFFEAE8E3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final pins = [
      Offset(w * 0.2, h * 0.32),
      Offset(w * 0.8, h * 0.28),
      Offset(w * 0.32, h * 0.76),
      Offset(w * 0.72, h * 0.72),
    ];
    for (final pin in pins) {
      canvas.drawLine(center, pin, linePaint);
    }

    // Central badge
    canvas.drawCircle(center, 26, Paint()..color = const Color(0xFFFF6600));
    canvas.drawCircle(center, 22, Paint()..color = Colors.white);

    // Search icon
    final searchPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(w / 2 - 2, h / 2 - 2), 6, searchPaint);
    canvas.drawLine(Offset(w / 2 + 2.5, h / 2 + 2.5), Offset(w / 2 + 9, h / 2 + 9), searchPaint);

    // Outer pins
    for (int i = 0; i < pins.length; i++) {
      final color = i.isEven ? const Color(0xFFFF6600) : const Color(0xFFFF9E4F);
      canvas.drawCircle(pins[i], 11, Paint()..color = color);
      canvas.drawCircle(pins[i], 4.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class DirectCommunicationIllustration extends StatelessWidget {
  const DirectCommunicationIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _DirectCommunicationPainter(),
    );
  }
}

class _DirectCommunicationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background bloom
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.44,
      Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    // Two device cards
    final cardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFFEAE8E3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cardRects = [
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.2, w * 0.32, h * 0.56), const Radius.circular(18)),
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.60, h * 0.2, w * 0.32, h * 0.56), const Radius.circular(18)),
    ];

    for (final r in cardRects) {
      canvas.drawRRect(r, Paint()..color = Colors.black.withValues(alpha: 0.025)..style = PaintingStyle.fill);
      canvas.drawRRect(r.shift(const Offset(0, -2)), cardPaint);
      canvas.drawRRect(r.shift(const Offset(0, -2)), borderPaint);
    }

    // Avatar circles
    canvas.drawCircle(Offset(w * 0.24, h * 0.48), 18, Paint()..color = const Color(0xFFFF6600));
    canvas.drawCircle(Offset(w * 0.24, h * 0.48), 7, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.76, h * 0.48), 18, Paint()..color = const Color(0xFFFF9E4F));
    canvas.drawCircle(Offset(w * 0.76, h * 0.48), 7, Paint()..color = Colors.white);

    // Curved bridge line
    final path = Path()
      ..moveTo(w * 0.24 + 18, h * 0.48)
      ..cubicTo(w * 0.42, h * 0.36, w * 0.58, h * 0.36, w * 0.76 - 18, h * 0.48);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF6600)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Arrow
    final arrow = Path()
      ..moveTo(w * 0.76 - 20, h * 0.48)
      ..lineTo(w * 0.76 - 28, h * 0.41)
      ..lineTo(w * 0.76 - 24, h * 0.50)
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFFFF6600));

    // Zero badge
    final badgePaint = Paint()..color = const Color(0xFF1E824C);
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), 14, badgePaint);
    final textSpan = TextSpan(
      text: '0%',
      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(w * 0.5 - tp.width / 2, h * 0.32 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class AiAssistantIllustration extends StatelessWidget {
  const AiAssistantIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _AiAssistantPainter(),
    );
  }
}

class _AiAssistantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.44,
      Paint()
        ..color = const Color(0xFFFF9E4F).withValues(alpha: 0.055)
        ..style = PaintingStyle.fill,
    );

    // AI speech bubble (orange)
    final bubble1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.55, h * 0.22),
      const Radius.circular(14),
    );
    canvas.drawRRect(bubble1, Paint()..color = const Color(0xFFFF6600));

    // Tail for AI bubble
    final tail1 = Path()
      ..moveTo(w * 0.18, h * 0.42)
      ..lineTo(w * 0.14, h * 0.52)
      ..lineTo(w * 0.28, h * 0.42)
      ..close();
    canvas.drawPath(tail1, Paint()..color = const Color(0xFFFF6600));

    // Dots inside AI bubble
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * 0.26 + i * w * 0.10, h * 0.31),
        3.5,
        Paint()..color = Colors.white,
      );
    }

    // User speech bubble
    final bubble2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.52, w * 0.55, h * 0.22),
      const Radius.circular(14),
    );
    canvas.drawRRect(bubble2, Paint()..color = const Color(0xFFF9F8F6));
    canvas.drawRRect(
      bubble2,
      Paint()
        ..color = const Color(0xFFEAE8E3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final tail2 = Path()
      ..moveTo(w * 0.82, h * 0.74)
      ..lineTo(w * 0.86, h * 0.82)
      ..lineTo(w * 0.74, h * 0.74)
      ..close();
    canvas.drawPath(tail2, Paint()..color = const Color(0xFFF9F8F6));

    // Mic icon in user bubble
    canvas.drawCircle(
      Offset(w * 0.625, h * 0.63),
      5,
      Paint()..color = const Color(0xFFFF9E4F),
    );

    // Sparkle dots
    final sparklePaint = Paint()..color = const Color(0xFFFF6600).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(w * 0.82, h * 0.2), 4, sparklePaint);
    canvas.drawCircle(Offset(w * 0.87, h * 0.28), 2.5, sparklePaint..color = const Color(0xFFFF9E4F).withValues(alpha: 0.5));
    canvas.drawCircle(Offset(w * 0.79, h * 0.14), 2, sparklePaint..color = const Color(0xFFFF6600).withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class CommunitySupportIllustration extends StatelessWidget {
  const CommunitySupportIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: _CommunitySupportPainter(),
    );
  }
}

class _CommunitySupportPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    canvas.drawCircle(
      center,
      w * 0.44,
      Paint()
        ..color = const Color(0xFFFF6600).withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    // Outer connection rings
    final wavePaint = Paint()
      ..color = const Color(0xFFFF9E4F).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 60, wavePaint);
    canvas.drawCircle(center, 78, wavePaint..color = const Color(0xFFFF9E4F).withValues(alpha: 0.1));

    // Central verified shield
    canvas.drawCircle(center, 36, Paint()..color = const Color(0xFFFF6600));
    canvas.drawCircle(center, 30, Paint()..color = Colors.white);

    // Check mark
    final check = Path()
      ..moveTo(w / 2 - 11, h / 2 - 1)
      ..lineTo(w / 2 - 2, h / 2 + 8)
      ..lineTo(w / 2 + 13, h / 2 - 8);
    canvas.drawPath(
      check,
      Paint()
        ..color = const Color(0xFFFF6600)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Community nodes
    final nodes = [
      Offset(w * 0.22, h * 0.28),
      Offset(w * 0.78, h * 0.28),
      Offset(w * 0.16, h * 0.68),
      Offset(w * 0.84, h * 0.68),
    ];

    for (final node in nodes) {
      canvas.drawLine(
        center,
        node,
        Paint()
          ..color = const Color(0xFFFF9E4F).withValues(alpha: 0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(node, 13, Paint()..color = const Color(0xFFFF9E4F));
      canvas.drawCircle(node, 5.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

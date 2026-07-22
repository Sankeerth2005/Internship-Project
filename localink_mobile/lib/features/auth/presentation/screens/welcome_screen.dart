import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Onboarding Page controller
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showRoleSelection = false;

  // Selected role: 'user', 'businessowner', or 'admin'
  String _selectedRole = 'user';
  bool _showAdmin = false;

  // Logo tap count for hidden admin gateway
  int _logoTapCount = 0;
  Timer? _logoTapTimer;

  @override
  void dispose() {
    _pageController.dispose();
    _logoTapTimer?.cancel();
    super.dispose();
  }

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
    setState(() {
      _showRoleSelection = true;
    });
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      setState(() {
        _showRoleSelection = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _showRoleSelection ? _buildRoleSelectionView() : _buildOnboardingView(),
      ),
    );
  }

  // ─── ONBOARDING SLIDES VIEW ───
  Widget _buildOnboardingView() {
    return SafeArea(
      key: const ValueKey('onboarding_view'),
      child: Column(
        children: [
          // Top bar with Skip option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Minimal branding
                Text(
                  'Vocal for Sanatan',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentColor,
                    letterSpacing: 1.0,
                  ),
                ),
                // Skip Button
                Semantics(
                  button: true,
                  label: 'Skip onboarding',
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48), // tap target size
                      foregroundColor: AppTheme.mutedTextColor,
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              ],
            ),
          ),

          // Slides PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildSlide(
                  illustration: const DiscoveryIllustration(),
                  headline: 'Discover Local Trust',
                  description:
                      'Connect with verified local businesses, organizations, and professionals in your neighborhood, backed by personal owner accountability.',
                ),
                _buildSlide(
                  illustration: const DirectCommunicationIllustration(),
                  headline: 'Direct and Fee-Free',
                  description:
                      'Get turn-by-turn directions and call owners directly with zero middleman commissions or hidden transaction costs.',
                ),
                _buildSlide(
                  illustration: const AiAssistantIllustration(),
                  headline: 'Meet Your AI Local Guide',
                  description:
                      'Search using natural voice commands or chat with our Llama-powered AI assistant to get instant recommendations as interactive cards.',
                ),
                _buildSlide(
                  illustration: const CommunitySupportIllustration(),
                  headline: 'Empower Your Community',
                  description:
                      'Save favorites, share local discoveries, request new listings, and directly submit feedback or complaints to improve your neighborhood.',
                ),
              ],
            ),
          ),

          // Bottom Navigation Row (Indicator & CTA Button)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Dots Indicator
                Row(
                  children: List.generate(4, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: isActive ? 24 : 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.accentColor : const Color(0xFFEAE8E3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Action Continue Button
                Semantics(
                  button: true,
                  label: _currentPage == 3 ? 'Get started' : 'Continue onboarding',
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 48), // tap target size
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentPage == 3 ? 'Get Started' : 'Continue'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required Widget illustration,
    required String headline,
    required String description,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double illustrationHeight = constraints.maxHeight * 0.45;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(height: constraints.maxHeight * 0.05),
                // Illustration Box
                SizedBox(
                  height: illustrationHeight,
                  width: double.infinity,
                  child: Center(child: illustration),
                ),
                SizedBox(height: constraints.maxHeight * 0.08),
                // Heading text
                Text(
                  headline,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1918),
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Descriptive copy text
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF5F5C58),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── ROLE SELECTION VIEW ───
  Widget _buildRoleSelectionView() {
    return SafeArea(
      key: const ValueKey('role_selection_view'),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Row header with Skip to home
                  Align(
                    alignment: Alignment.topRight,
                    child: Semantics(
                      button: true,
                      label: 'Skip login and explore directly',
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.go('/home');
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: AppTheme.accentColor,
                        ),
                        child: const Text('Skip & Explore'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Emblem Logo Badge - triple tap hidden portal
                  GestureDetector(
                    onTap: _onLogoTap,
                    child: Hero(
                      tag: 'app_logo',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primarySolarGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                blurRadius: 16,
                                spreadRadius: 1,
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
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Titles
                  const Text(
                    'Vocal for Sanatan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select Your Profile',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1918),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the profile configuration that best matches your daily operations.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF5F5C58),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Cards layout list
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Consumer Card
                      Expanded(
                        child: _buildRoleCard(
                          roleKey: 'user',
                          title: 'User',
                          description: 'Discover shops',
                          icon: Icons.person_outline_rounded,
                          isSelected: _selectedRole == 'user',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Merchant Card
                      Expanded(
                        child: _buildRoleCard(
                          roleKey: 'businessowner',
                          title: 'Business',
                          description: 'Register store',
                          icon: Icons.storefront_rounded,
                          isSelected: _selectedRole == 'businessowner',
                        ),
                      ),
                      // Admin Card - visible only when gateway triggered
                      if (_showAdmin) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRoleCard(
                            roleKey: 'admin',
                            title: 'Admin',
                            description: 'Governance',
                            icon: Icons.admin_panel_settings_outlined,
                            isSelected: _selectedRole == 'admin',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Contextual Checklist Details Card
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(_selectedRole),
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _getFeaturesForRole(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Core CTA buttons at bottom
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary Action Button
                Semantics(
                  button: true,
                  label: _selectedRole == 'admin' ? 'Login as moderator admin' : 'Continue to authentication',
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.go('/login', extra: _selectedRole);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedRole == 'admin' ? 'Login as Admin' : 'Continue',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Register Secondary Link
                if (_selectedRole != 'admin')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New here? ',
                        style: TextStyle(
                          color: Color(0xFF5F5C58),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.go('/signup', extra: _selectedRole);
                        },
                        child: const Text(
                          'Create an Account',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleKey,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedRole = roleKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6600).withOpacity(0.06) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            // Checkmark indicator
            Align(
              alignment: Alignment.topRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.accentColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppTheme.accentColor : AppTheme.borderColor,
                    width: 1.2,
                  ),
                ),
                child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
              ),
            ),
            const SizedBox(height: 8),

            // Icon circle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.accentColor : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : AppTheme.mutedTextColor,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.accentColor : const Color(0xFF1A1918),
              ),
            ),
            const SizedBox(height: 4),

            // Subtext Description
            Text(
              description,
              style: TextStyle(
                fontSize: 10.5,
                color: AppTheme.mutedTextColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getFeaturesForRole() {
    if (_selectedRole == 'user') {
      return [
        _buildFeatureBullet('Discover local businesses & services easily.'),
        const SizedBox(height: 10),
        _buildFeatureBullet('Connect with verified local professionals.'),
        const SizedBox(height: 10),
        _buildFeatureBullet('AI voice search & smart recommendations.'),
      ];
    } else if (_selectedRole == 'businessowner') {
      return [
        _buildFeatureBullet('List & promote your store for 100% free.'),
        const SizedBox(height: 10),
        _buildFeatureBullet('Manage operating hours, photos, and location.'),
        const SizedBox(height: 10),
        _buildFeatureBullet('Receive customer leads, views & ratings.'),
      ];
    } else {
      return [
        _buildFeatureBullet('Review and approve business listings.'),
        const SizedBox(height: 10),
        _buildFeatureBullet('Manage categories & system reports.'),
        const SizedBox(height: 10),
        _buildFeatureBullet('Full platform governance & user control.'),
      ];
    }
  }

  Widget _buildFeatureBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF5F5C58),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 1. DISCOVERY ILLUSTRATION PAINTER ───
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

    final bgPaint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.45, bgPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFFFF9E4F).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, w * 0.3, ringPaint);
    canvas.drawCircle(center, w * 0.18, ringPaint);

    // Draw connecting lines
    final linePaint = Paint()
      ..color = const Color(0xFFEAE8E3)
      ..strokeWidth = 2.0;
    canvas.drawLine(center, Offset(w * 0.2, h * 0.35), linePaint);
    canvas.drawLine(center, Offset(w * 0.8, h * 0.3), linePaint);
    canvas.drawLine(center, Offset(w * 0.35, h * 0.75), linePaint);
    canvas.drawLine(center, Offset(w * 0.7, h * 0.7), linePaint);

    // Draw central discovery shield
    final shieldPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 24, shieldPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20, innerPaint);

    final searchIconPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(w / 2 - 2, h / 2 - 2), 6, searchIconPaint);
    canvas.drawLine(Offset(w / 2 + 2, h / 2 + 2), Offset(w / 2 + 9, h / 2 + 9), searchIconPaint);

    // Draw outer pins
    _drawPin(canvas, Offset(w * 0.2, h * 0.35), const Color(0xFFFF9E4F));
    _drawPin(canvas, Offset(w * 0.8, h * 0.3), const Color(0xFFFF6600));
    _drawPin(canvas, Offset(w * 0.35, h * 0.75), const Color(0xFFFF6600));
    _drawPin(canvas, Offset(w * 0.7, h * 0.7), const Color(0xFFFF9E4F));
  }

  void _drawPin(Canvas canvas, Offset pos, Color color) {
    final pinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 10, pinPaint);

    final centerWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 4, centerWhite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 2. DIRECT COMMUNICATION ILLUSTRATION PAINTER ───
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

    final bgPaint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.45, bgPaint);

    // Draw phone silhouette
    final cardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final cardShadow = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Draw background shadows
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.24, w * 0.28, h * 0.52), const Radius.circular(16)), cardShadow);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.54, h * 0.24, w * 0.28, h * 0.52), const Radius.circular(16)), cardShadow);

    // Draw cards
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.28, h * 0.52), const Radius.circular(16)), cardPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.54, h * 0.22, w * 0.28, h * 0.52), const Radius.circular(16)), cardPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFEAE8E3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.28, h * 0.52), const Radius.circular(16)), borderPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.54, h * 0.22, w * 0.28, h * 0.52), const Radius.circular(16)), borderPaint);

    // Phone / call icon details
    final phonePaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.32, h * 0.48), 16, phonePaint);
    
    // User profile icon details
    final userPaint = Paint()
      ..color = const Color(0xFFFF9E4F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.68, h * 0.48), 16, userPaint);

    // Dynamic bridge line
    final bridgePaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final path = Path();
    path.moveTo(w * 0.32 + 16, h * 0.48);
    path.cubicTo(w * 0.44, h * 0.38, w * 0.56, h * 0.38, w * 0.68 - 16, h * 0.48);
    canvas.drawPath(path, bridgePaint);

    // Arrow tips
    final arrowPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.fill;
    final arrowPath = Path();
    arrowPath.moveTo(w * 0.68 - 18, h * 0.48);
    arrowPath.lineTo(w * 0.68 - 26, h * 0.42);
    arrowPath.lineTo(w * 0.68 - 22, h * 0.50);
    arrowPath.close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 3. AI ASSISTANT ILLUSTRATION PAINTER ───
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

    final bgPaint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.45, bgPaint);

    // Draw speech bubble 1 (AI)
    final bubblePaint1 = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.fill;
    final bubbleRect1 = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.25, w * 0.5, h * 0.22), const Radius.circular(14));
    canvas.drawRRect(bubbleRect1, bubblePaint1);

    final tailPath1 = Path();
    tailPath1.moveTo(w * 0.22, h * 0.47);
    tailPath1.lineTo(w * 0.18, h * 0.54);
    tailPath1.lineTo(w * 0.30, h * 0.47);
    tailPath1.close();
    canvas.drawPath(tailPath1, bubblePaint1);

    // Draw speech bubble 2 (User)
    final bubblePaint2 = Paint()
      ..color = const Color(0xFFF9F8F6)
      ..style = PaintingStyle.fill;
    final borderPaint2 = Paint()
      ..color = const Color(0xFFEAE8E3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final bubbleRect2 = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.35, h * 0.53, w * 0.5, h * 0.22), const Radius.circular(14));
    canvas.drawRRect(bubbleRect2, bubblePaint2);
    canvas.drawRRect(bubbleRect2, borderPaint2);

    final tailPath2 = Path();
    tailPath2.moveTo(w * 0.78, h * 0.75);
    tailPath2.lineTo(w * 0.82, h * 0.82);
    tailPath2.lineTo(w * 0.70, h * 0.75);
    tailPath2.close();
    canvas.drawPath(tailPath2, bubblePaint2);
    canvas.drawPath(tailPath2, borderPaint2);

    // Draw dots inside AI bubble representing thinking
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.3, h * 0.36), 3.5, whitePaint);
    canvas.drawCircle(Offset(w * 0.4, h * 0.36), 3.5, whitePaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.36), 3.5, whitePaint);

    // Draw mini glowing star in user bubble
    final starPaint = Paint()
      ..color = const Color(0xFFFF9E4F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.6, h * 0.64), 5, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 4. COMMUNITY SUPPORT ILLUSTRATION PAINTER ───
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

    final bgPaint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.45, bgPaint);

    // Draw a premium circular shield
    final shieldPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 40, shieldPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 34, innerPaint);

    // Draw check icon in shield
    final checkPaint = Paint()
      ..color = const Color(0xFFFF6600)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final checkPath = Path();
    checkPath.moveTo(w / 2 - 12, h / 2 - 2);
    checkPath.lineTo(w / 2 - 2, h / 2 + 8);
    checkPath.lineTo(w / 2 + 14, h / 2 - 8);
    canvas.drawPath(checkPath, checkPaint);

    // Draw outer floating community nodes (people silhouettes)
    final nodePaint = Paint()
      ..color = const Color(0xFFFF9E4F)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.25, h * 0.3), 12, nodePaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.3), 12, nodePaint);
    canvas.drawCircle(Offset(w * 0.18, h * 0.65), 12, nodePaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.65), 12, nodePaint);

    // Draw connection waves
    final wavePaint = Paint()
      ..color = const Color(0xFFFF9E4F).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(Rect.fromCircle(center: center, radius: 60), -0.2, 0.4, false, wavePaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: 60), 2.9, 0.4, false, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // Selected role: 'user', 'client', or 'admin'
  String _selectedRole = 'client';

  late AnimationController _particleController;
  final List<EmberParticle> _particles =
      List.generate(45, (index) => EmberParticle());

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
        });
      });
    _particleController.repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070504),
      body: Stack(
        children: [
          // ─── 1. DYNAMIC DIVINE SOLAR HALO & PARTICLE CANVAS ───
          Positioned.fill(
            child: CustomPaint(
              painter: WelcomeBackgroundPainter(_particles),
            ),
          ),

          // ─── 2. ADAPTIVE RESPONSIVE CONTENT LAYOUT ───
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ─── TOP BADGE & HERO HEADER ───
                          Column(
                            children: [
                              const SizedBox(height: 12),
                              // Glassmorphic Luxury Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF181008).withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFFF9D00).withValues(alpha: 0.4),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF9D00).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 12,
                                      color: Color(0xFFFFB300),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'VOCAL FOR SANATAN',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFFFB300),
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 12,
                                      color: Color(0xFFFFB300),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 80),

                              // Title 1: "Welcome to" (Serif)
                              const Text(
                                'Welcome to',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFF5EFE6),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Title 2: "Vocal for Sanatan" (Metallic Golden Serif Gradient)
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Color(0xFFFFFDF0),
                                      Color(0xFFFFE082),
                                      Color(0xFFFF9100),
                                      Color(0xFFE65100),
                                    ],
                                    stops: [0.0, 0.35, 0.75, 1.0],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'Vocal for Sanatan',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 33,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xAAFF6A00),
                                        blurRadius: 16,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Ornamental Lotus Line Divider: ─── 🪷 ───
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 1.2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFFFF9D00).withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(
                                      Icons.filter_vintage_rounded,
                                      size: 15,
                                      color: Color(0xFFFF9100),
                                    ),
                                  ),
                                  Container(
                                    width: 50,
                                    height: 1.2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFFF9D00).withValues(alpha: 0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Subtitle Paragraph
                              const Text(
                                'One platform, many roles.\nConnect, contribute and empower\nour Sanatan heritage.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  color: Color(0xFFD4C7B8),
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ─── ROLE SELECTOR SECTION ───
                          Column(
                            children: [
                              // Section Header: ❖ CHOOSE YOUR ROLE ❖
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            const Color(0xFFFF8C00).withValues(alpha: 0.5),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6.0),
                                    child: Icon(Icons.diamond_rounded, size: 7, color: Color(0xFFFF9100)),
                                  ),
                                  const Text(
                                    'CHOOSE YOUR ROLE',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFF9100),
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6.0),
                                    child: Icon(Icons.diamond_rounded, size: 7, color: Color(0xFFFF9100)),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFFF8C00).withValues(alpha: 0.5),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // 3 Glassmorphic Role Cards (User, Client, Admin)
                              SizedBox(
                                height: 205,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Card 1: User
                                    Expanded(
                                      child: _buildRoleCard(
                                        roleKey: 'user',
                                        title: 'User',
                                        description: 'Discover local businesses, explore services and support your community.',
                                        icon: Icons.person_outline_rounded,
                                        isSelected: _selectedRole == 'user',
                                        artPainter: UserCardArtPainter(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Card 2: Client
                                    Expanded(
                                      child: _buildRoleCard(
                                        roleKey: 'client',
                                        title: 'Client',
                                        description: 'Manage your business, connect with customers and grow your brand with AI insights.',
                                        icon: Icons.storefront_rounded,
                                        isSelected: _selectedRole == 'client',
                                        artPainter: BusinessCardArtPainter(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Card 3: Admin
                                    Expanded(
                                      child: _buildRoleCard(
                                        roleKey: 'admin',
                                        title: 'Admin',
                                        description: 'Oversee platform operations, manage users and ensure quality & trust.',
                                        icon: Icons.shield_outlined,
                                        isSelected: _selectedRole == 'admin',
                                        artPainter: AdminCardArtPainter(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ─── ACTION CTA BUTTON & TRUST FOOTER ───
                          Column(
                            children: [
                              // Primary Action Button ("Continue ->")
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF7700),
                                        Color(0xFFD63800),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0x77FF6A00),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      context.go('/login', extra: _selectedRole);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Spacer(),
                                        const Text(
                                          'Continue',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFFF9E1B),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Trust Subtext: Shield + "Trusted. Verified. Secure."
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 14,
                                    color: Color(0xFFFF9100),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Trusted. Verified. Secure.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFFB5A99B),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Accent Line Divider: ─── ◆ ───
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 0.8,
                                      color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(Icons.diamond_rounded, size: 6, color: Color(0xFFFF9100)),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 0.8,
                                      color: const Color(0xFFFF8C00).withValues(alpha: 0.25),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // 4 Glass Feature Tiles
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildBottomFeature(
                                    icon: Icons.account_balance_rounded,
                                    label: 'Preserve\nHeritage',
                                  ),
                                  _buildBottomFeature(
                                    icon: Icons.groups_rounded,
                                    label: 'Empower\nCommunities',
                                  ),
                                  _buildBottomFeature(
                                    icon: Icons.verified_user_rounded,
                                    label: 'Secure &\nVerified',
                                  ),
                                  _buildBottomFeature(
                                    icon: Icons.auto_awesome_rounded,
                                    label: 'AI Powered\nPlatform',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ],
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

  Widget _buildRoleCard({
    required String roleKey,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required CustomPainter artPainter,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedRole = roleKey;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF16110B)
                  : const Color(0xFF0E0B09).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF7A00)
                    : const Color(0xFF281F17),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0x66FF7A00),
                        blurRadius: 20,
                        spreadRadius: 2.0,
                      ),
                      BoxShadow(
                        color: const Color(0x33FF4500),
                        blurRadius: 36,
                        spreadRadius: 4.0,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    // Top Icon Container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF2C1A0A)
                            : const Color(0xFF1A140E),
                        border: Border.all(
                          color: const Color(0xFFFF7A00).withValues(alpha: isSelected ? 1.0 : 0.4),
                          width: isSelected ? 1.6 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF7A00).withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: roleKey == 'admin'
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_rounded,
                                    size: 21,
                                    color: isSelected
                                        ? const Color(0xFFFF9100)
                                        : const Color(0xFFFF9100).withValues(alpha: 0.7),
                                  ),
                                  Icon(
                                    Icons.star_rounded,
                                    size: 9,
                                    color: isSelected ? Colors.black : const Color(0xFF1A140E),
                                  ),
                                ],
                              )
                            : Icon(
                                icon,
                                size: 21,
                                color: isSelected
                                    ? const Color(0xFFFF9100)
                                    : const Color(0xFFFF9100).withValues(alpha: 0.7),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Role Title
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? const Color(0xFFFF9100) : Colors.white,
                        shadows: isSelected
                            ? [
                                const Shadow(
                                  color: Color(0x99FF7A00),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 3),

                    // Indicator Line Under Title
                    Container(
                      width: 16,
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9100).withValues(alpha: isSelected ? 1.0 : 0.4),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF7A00).withValues(alpha: 0.6),
                                  blurRadius: 6,
                                ),
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Card Description (Full visibility on all screen sizes)
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.0,
                        color: Color(0xFFA59B90),
                        height: 1.28,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                    ),
                  ],
                ),

                // Card Bottom Custom Line-Art
                SizedBox(
                  height: 22,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: artPainter,
                  ),
                ),
              ],
            ),
          ),

          // Top-Right Orange Star Badge when Selected
          if (isSelected)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF7A00),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.75),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomFeature({
    required IconData icon,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF16110B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFFFF9100),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.0,
            color: Color(0xFFB0A59A),
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── AMBIENT EMBER PARTICLE MODEL ───

class EmberParticle {
  late double x;
  late double y;
  late double speedY;
  late double speedX;
  late double size;
  late double opacity;

  EmberParticle() {
    reset(isInitial: true);
  }

  void reset({bool isInitial = false}) {
    final rand = math.Random();
    x = rand.nextDouble();
    y = isInitial ? rand.nextDouble() : 1.05;
    speedY = 0.0005 + rand.nextDouble() * 0.0015;
    speedX = (rand.nextDouble() - 0.5) * 0.0004;
    size = 1.0 + rand.nextDouble() * 2.5;
    opacity = 0.2 + rand.nextDouble() * 0.65;
  }

  void update() {
    y -= speedY;
    x += speedX + math.sin(y * 12) * 0.0003;

    if (y < -0.05 || x < -0.05 || x > 1.05) {
      reset();
    }
  }
}

// ─── ULTRA-PREMIUM DIVINE SOLAR HALO BACKGROUND PAINTER ───

class WelcomeBackgroundPainter extends CustomPainter {
  final List<EmberParticle> particles;

  WelcomeBackgroundPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Deep Obsidian Base Gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF090604),
          Color(0xFF070504),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawRect(rect, bgPaint);

    // 2. Solar Halo Radiant Aura (Multi-Stop Soft Radial Gradient)
    final sunCenter = Offset(size.width * 0.5, 80.0);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.78),
        radius: 0.70,
        colors: [
          const Color(0xFFFF7700).withValues(alpha: 0.50),
          const Color(0xFFE65100).withValues(alpha: 0.32),
          const Color(0xFF3E1400).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, glowPaint);

    // 3. Glowing Sun Core Disc
    final sunPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFFFFF8DC),
          const Color(0xFFFF9100).withValues(alpha: 0.85),
          const Color(0xFFFF5500).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: size.width * 0.28));

    canvas.drawCircle(sunCenter, size.width * 0.28, sunPaint);

    // 4. Floating Golden Ember Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      particlePaint.color = const Color(0xFFFF9100).withValues(alpha: p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        particlePaint,
      );
    }

    // 5. Golden Glowing Light Swooshes (Curved Light Arcs across Sky)
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 4; i++) {
      wavePaint.color = const Color(0xFFFF8C00).withValues(alpha: 0.18 + i * 0.05);
      final path = Path();
      double yOffset = 60.0 + i * 14;
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.28,
        yOffset - 25 + i * 10,
        size.width * 0.72,
        yOffset + 30 - i * 8,
        size.width,
        yOffset - 12,
      );
      canvas.drawPath(path, wavePaint);
    }

    // 6. SACRED OM EMBLEM RING (CENTERED AT TOP ~100px)
    final emblemX = size.width * 0.5;
    final emblemY = 100.0;

    final gearRadius = 26.0;
    final gearPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Gear teeth outer ring
    canvas.drawCircle(Offset(emblemX, emblemY), gearRadius, gearPaint);

    final toothPaint = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final angle = (i * 18) * math.pi / 180;
      final dx = emblemX + (gearRadius + 3.5) * math.cos(angle);
      final dy = emblemY + (gearRadius + 3.5) * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.4, toothPaint);
    }

    // Inner dark circle container
    final innerBgPaint = Paint()
      ..color = const Color(0xFF0F0905)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(emblemX, emblemY), gearRadius - 2, innerBgPaint);

    // Flag + Om inside Central Emblem
    final polePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 1.5;

    final flagPaint = Paint()
      ..color = const Color(0xFFFF7700)
      ..style = PaintingStyle.fill;

    final emblemFlagPath = Path()
      ..moveTo(emblemX - 5, emblemY - 10)
      ..lineTo(emblemX + 9, emblemY - 5)
      ..lineTo(emblemX - 5, emblemY)
      ..close();

    canvas.drawLine(
      Offset(emblemX - 5, emblemY - 12),
      Offset(emblemX - 5, emblemY + 10),
      polePaint,
    );

    canvas.drawPath(emblemFlagPath, flagPaint);

    const omSpan = TextSpan(
      text: 'ॐ',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFD166),
      ),
    );

    final omPainter = TextPainter(
      text: omSpan,
      textDirection: TextDirection.ltr,
    );
    omPainter.layout();
    omPainter.paint(
      canvas,
      Offset(emblemX - omPainter.width / 2 + 1, emblemY + 1),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── CARD BOTTOM LINE-ART CUSTOM PAINTERS ───

class UserCardArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A00).withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.15, size.height * 0.65);
    path.lineTo(size.width * 0.3, size.height * 0.8);
    path.lineTo(size.width * 0.5, size.height * 0.25);
    path.lineTo(size.width * 0.7, size.height * 0.8);
    path.lineTo(size.width * 0.85, size.height * 0.65);
    path.lineTo(size.width, size.height);

    canvas.drawPath(path, paint);

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), 1.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BusinessCardArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A00).withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double barWidth = size.width * 0.11;
    double h1 = size.height * 0.3;
    double h2 = size.height * 0.52;
    double h3 = size.height * 0.75;
    double h4 = size.height * 0.92;

    canvas.drawRect(Rect.fromLTWH(size.width * 0.08, size.height - h1, barWidth, h1), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.28, size.height - h2, barWidth, h2), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.48, size.height - h3, barWidth, h3), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.68, size.height - h4, barWidth, h4), paint);

    final linePath = Path()
      ..moveTo(size.width * 0.08, size.height - h1 - 4)
      ..lineTo(size.width * 0.33, size.height - h2 - 4)
      ..lineTo(size.width * 0.53, size.height - h3 - 4)
      ..lineTo(size.width * 0.85, size.height - h4 - 6);

    paint.color = const Color(0xFFFF9100).withValues(alpha: 0.75);
    paint.strokeWidth = 1.2;
    canvas.drawPath(linePath, paint);

    // Arrow tip
    final arrowPath = Path()
      ..moveTo(size.width * 0.78, size.height - h4 - 6)
      ..lineTo(size.width * 0.85, size.height - h4 - 6)
      ..lineTo(size.width * 0.85, size.height - h4 + 1);

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AdminCardArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A00).withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final shieldPath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.25)
      ..lineTo(size.width * 0.44, size.height * 0.25)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..cubicTo(size.width * 0.44, size.height * 0.9, size.width * 0.33, size.height, size.width * 0.33, size.height)
      ..cubicTo(size.width * 0.33, size.height, size.width * 0.22, size.height * 0.9, size.width * 0.22, size.height * 0.68)
      ..close();

    canvas.drawPath(shieldPath, paint);

    // Inner shield emblem star
    paint.color = const Color(0xFFFF9100).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(size.width * 0.33, size.height * 0.5), 2.5, paint);

    // Dashboard card window on right
    paint.color = const Color(0xFFFF7A00).withValues(alpha: 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.52, size.height * 0.3, size.width * 0.42, size.height * 0.6),
        const Radius.circular(4),
      ),
      paint,
    );

    // Sub-lines in dashboard
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.5),
      Offset(size.width * 0.86, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.7),
      Offset(size.width * 0.76, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

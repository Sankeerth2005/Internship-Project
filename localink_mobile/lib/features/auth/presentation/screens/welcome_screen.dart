import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Selected role: 'user', 'businessowner', or 'admin'
  String _selectedRole = 'user';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080706),
      body: Stack(
        children: [
          // Background ambient gradient lighting
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.7),
                  radius: 1.3,
                  colors: [
                    const Color(0xFFFF7A00).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, 0.7),
                  radius: 1.3,
                  colors: [
                    const Color(0xFFFF5500).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        // Compact App Emblem/Logo Badge
                        Container(
                          width: 64,
                          height: 64,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9F00), Color(0xFFFF5500)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF141210),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'ॐ',
                                style: TextStyle(
                                  color: Color(0xFFFF7A00),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title & Header
                        const Text(
                          'Vocal for Sanatan',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF7A00),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select Your Role',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose the account type that best describes your needs.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // 3 Compact Role Selection Cards Side-by-Side
                        Row(
                          children: [
                            // Card 1: User / Customer
                            Expanded(
                              child: _buildRoleCard(
                                roleKey: 'user',
                                title: 'User',
                                icon: Icons.person_rounded,
                                isSelected: _selectedRole == 'user',
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Card 2: Business Owner / Vendor
                            Expanded(
                              child: _buildRoleCard(
                                roleKey: 'businessowner',
                                title: 'Business',
                                icon: Icons.storefront_rounded,
                                isSelected: _selectedRole == 'businessowner',
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Card 3: Admin
                            Expanded(
                              child: _buildRoleCard(
                                roleKey: 'admin',
                                title: 'Admin',
                                icon: Icons.admin_panel_settings_rounded,
                                isSelected: _selectedRole == 'admin',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Dynamic Feature Bullets Box
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            key: ValueKey(_selectedRole),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141210),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _selectedRole == 'user'
                                  ? [
                                      _buildFeatureBullet('Discover local businesses & services easily.'),
                                      const SizedBox(height: 8),
                                      _buildFeatureBullet('Connect with verified local professionals.'),
                                      const SizedBox(height: 8),
                                      _buildFeatureBullet('AI voice search & smart recommendations.'),
                                    ]
                                  : _selectedRole == 'businessowner'
                                      ? [
                                          _buildFeatureBullet('List & promote your store for 100% free.'),
                                          const SizedBox(height: 8),
                                          _buildFeatureBullet('Manage operating hours, photos, and location.'),
                                          const SizedBox(height: 8),
                                          _buildFeatureBullet('Receive customer leads, views & ratings.'),
                                        ]
                                      : [
                                          _buildFeatureBullet('Review and approve business listings.'),
                                          const SizedBox(height: 8),
                                          _buildFeatureBullet('Manage categories & system reports.'),
                                          const SizedBox(height: 8),
                                          _buildFeatureBullet('Full platform governance & user control.'),
                                        ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // Floating Action Button at Bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/login', extra: _selectedRole);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 6,
                            shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.35),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedRole == 'admin' ? 'Login as Admin' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedRole != 'admin')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'New here? ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.go('/signup', extra: _selectedRole);
                              },
                              child: const Text(
                                'Create an Account',
                                style: TextStyle(
                                  color: Color(0xFFFF7A00),
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
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleKey,
    required String title,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF7A00).withValues(alpha: 0.12)
              : const Color(0xFF141210),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF7A00)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                    blurRadius: 12,
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
                  color: isSelected ? const Color(0xFFFF7A00) : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            // Circle Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFFF7A00)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF7A00),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

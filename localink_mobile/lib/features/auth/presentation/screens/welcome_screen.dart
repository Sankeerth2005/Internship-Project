import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Default selected role: 'user' (Customer) or 'businessowner' (Business)
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
                    const Color(0xFFFF7A00).withValues(alpha: 0.1),
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
                    const Color(0xFFFF5500).withValues(alpha: 0.08),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 15),
                        // App Brand Logo Badge
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9F00), Color(0xFFFF5500)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF7A00).withValues(alpha: 0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
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
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // App Headline & Title
                        const Text(
                          'Vocal for Sanatan',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF7A00),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select Your Role',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose the account type that best describes your needs.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // Two Role Selection Cards Side-by-Side
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
                            const SizedBox(width: 16),
                            // Card 2: Business Owner / Vendor
                            Expanded(
                              child: _buildRoleCard(
                                roleKey: 'businessowner',
                                title: 'Business',
                                icon: Icons.storefront_rounded,
                                isSelected: _selectedRole == 'businessowner',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Feature Bullets List Card based on selected role
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            key: ValueKey(_selectedRole),
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141210),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _selectedRole == 'user'
                                  ? [
                                      _buildFeatureBullet('Discover local businesses & services easily.'),
                                      const SizedBox(height: 12),
                                      _buildFeatureBullet('Connect with verified local professionals.'),
                                      const SizedBox(height: 12),
                                      _buildFeatureBullet('Enjoy AI voice search & smart recommendations.'),
                                    ]
                                  : [
                                      _buildFeatureBullet('List & promote your store for 100% free.'),
                                      const SizedBox(height: 12),
                                      _buildFeatureBullet('Manage operating hours, photos, and location.'),
                                      const SizedBox(height: 12),
                                      _buildFeatureBullet('Receive customer leads, views & ratings.'),
                                    ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Floating Full-Width Action Button at Bottom
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/login', extra: _selectedRole);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New here? ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
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
                                fontSize: 14,
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF7A00).withValues(alpha: 0.12)
              : const Color(0xFF141210),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF7A00)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            // Checked badge indicator
            Align(
              alignment: Alignment.topRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFFFF7A00) : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            // Circle Icon Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFFF7A00)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
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
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF7A00),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

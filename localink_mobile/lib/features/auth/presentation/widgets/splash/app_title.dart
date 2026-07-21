import 'package:flutter/material.dart';

/// Layer 9 & 10: App Title & Tagline with timed fade-in and translateY animations
class AppTitle extends StatelessWidget {
  final Animation<double> titleFadeAnimation;
  final Animation<double> titleTranslateAnimation;
  final Animation<double> taglineFadeAnimation;
  final Animation<double> taglineTranslateAnimation;

  const AppTitle({
    super.key,
    required this.titleFadeAnimation,
    required this.titleTranslateAnimation,
    required this.taglineFadeAnimation,
    required this.taglineTranslateAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Layer 9: Title "VOCAL FOR SANATAN"
        AnimatedBuilder(
          animation: Listenable.merge([titleFadeAnimation, titleTranslateAnimation]),
          builder: (context, child) {
            return Opacity(
              opacity: titleFadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, titleTranslateAnimation.value),
                child: const Text(
                  'VOCAL FOR SANATAN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3.5,
                    shadows: [
                      Shadow(
                        color: Color(0xFFFF8C00),
                        blurRadius: 18,
                      ),
                      Shadow(
                        color: Colors.black,
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Ornamental Divider
        AnimatedBuilder(
          animation: titleFadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: titleFadeAnimation.value * 0.7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 1,
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC857), size: 10),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 1,
                    color: const Color(0xFFFF8C00).withValues(alpha: 0.5),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Layer 10: Tagline "Discover & Support Local Heritage"
        AnimatedBuilder(
          animation: Listenable.merge([taglineFadeAnimation, taglineTranslateAnimation]),
          builder: (context, child) {
            return Opacity(
              opacity: taglineFadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, taglineTranslateAnimation.value),
                child: Text(
                  'Discover & Support Local Heritage',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Layer 11: Glowing Orange Loading Indicator Line (Grows Left -> Right over 1 second)
class LoadingBar extends StatelessWidget {
  final Animation<double> progressAnimation;
  final double width;

  const LoadingBar({
    super.key,
    required this.progressAnimation,
    this.width = 160.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressAnimation,
      builder: (context, child) {
        final progress = progressAnimation.value.clamp(0.0, 1.0);
        return Container(
          width: width,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF5500),
                      Color(0xFFFF8C00),
                      Color(0xFFFFC857),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

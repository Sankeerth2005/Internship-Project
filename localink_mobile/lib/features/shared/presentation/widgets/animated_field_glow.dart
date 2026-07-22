import 'package:flutter/material.dart';

class AnimatedFieldGlow extends StatelessWidget {
  final bool isFocused;
  final Widget child;
  final double borderRadius;

  const AnimatedFieldGlow({
    super.key,
    required this.isFocused,
    required this.child,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFFFF6600).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}

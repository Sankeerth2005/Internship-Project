import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BrandIconBadge extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final double size;

  const BrandIconBadge({
    super.key,
    this.icon,
    this.text,
    this.size = 72,
  }) : assert(icon != null || text != null, 'Either icon or text must be provided');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.05),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primarySolarGradient,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6600).withValues(alpha: 0.24),
              blurRadius: size * 0.28,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    color: const Color(0xFFFF6600),
                    size: size * 0.44,
                  )
                : Text(
                    text!,
                    style: TextStyle(
                      color: const Color(0xFFFF6600),
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

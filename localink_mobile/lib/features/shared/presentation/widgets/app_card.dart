import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.color,
    this.border,
    this.boxShadow,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
      padding: padding ?? const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(color: AppTheme.borderColor.withValues(alpha: 0.9)),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: const Color(0xFF1A1918).withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );
  }
}

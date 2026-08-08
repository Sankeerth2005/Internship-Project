import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_icons.dart';

/// Circular brand mark — uses the Om asset by default (not a text glyph).
class BrandIconBadge extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final double size;
  final bool useOm;

  const BrandIconBadge({
    super.key,
    this.icon,
    this.text,
    this.size = 72,
    this.useOm = false,
  }) : assert(
          icon != null || text != null || useOm,
          'Provide icon, text, or useOm: true',
        );

  /// Preferred brand logo badge.
  const BrandIconBadge.om({
    super.key,
    this.size = 72,
  })  : icon = null,
        text = null,
        useOm = true;

  bool get _showOm {
    if (useOm) return true;
    if (icon != null) return false;
    final t = text?.trim();
    return t == 'ॐ' || t == 'Om' || t == 'OM';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.06),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primarySolarGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.22),
              blurRadius: size * 0.32,
              offset: Offset(0, size * 0.1),
            ),
            BoxShadow(
              color: AppTheme.glowColor.withValues(alpha: 0.12),
              blurRadius: size * 0.5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.accentColor.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Center(
            child: _showOm
                ? Padding(
                    padding: EdgeInsets.all(size * 0.14),
                    child: BrandIcons.om(size: size * 0.52),
                  )
                : icon != null
                    ? Icon(
                        icon,
                        color: AppTheme.accentColor,
                        size: size * 0.42,
                      )
                    : Text(
                        text!,
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: size * 0.36,
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

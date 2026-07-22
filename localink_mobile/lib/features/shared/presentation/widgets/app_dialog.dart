import 'package:flutter/material.dart';
import 'animated_checkmark.dart';
import '../../../../core/theme/app_theme.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final Widget? icon;
  final List<Widget>? actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(height: 24),
            ],
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1918),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF5F5C58),
              ),
              textAlign: TextAlign.center,
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return AppDialog(
          title: title,
          message: message,
          icon: const AnimatedCheckmark(),
        );
      },
    );
    return Future.delayed(duration);
  }
}

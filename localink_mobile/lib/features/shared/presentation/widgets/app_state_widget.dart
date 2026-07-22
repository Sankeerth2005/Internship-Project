import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum AppStateType { loading, error, empty, success }

class AppStateWidget extends StatelessWidget {
  final AppStateType type;
  final String title;
  final String description;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const AppStateWidget({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case AppStateType.loading:
        return const Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentColor,
            strokeWidth: 3.0,
          ),
        );
      case AppStateType.error:
        icon = Icons.error_outline_rounded;
        iconColor = AppTheme.errorColor;
        break;
      case AppStateType.empty:
        icon = Icons.inbox_rounded;
        iconColor = AppTheme.mutedTextColor;
        break;
      case AppStateType.success:
        icon = Icons.check_circle_outline_rounded;
        iconColor = AppTheme.tricolorGreen;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1918),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF5F5C58),
              ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

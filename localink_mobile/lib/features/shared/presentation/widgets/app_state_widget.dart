import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

enum AppStateType { loading, error, empty, success, offline }

class AppStateWidget extends StatelessWidget {
  final AppStateType type;
  final String title;
  final String description;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final IconData? icon;
  final bool compact;

  const AppStateWidget({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    this.onActionPressed,
    this.actionLabel,
    this.icon,
    this.compact = false,
  });

  factory AppStateWidget.error({
    Key? key,
    required String message,
    VoidCallback? onRetry,
  }) {
    return AppStateWidget(
      key: key,
      type: AppStateType.error,
      title: 'Something went wrong',
      description: message,
      onActionPressed: onRetry,
      actionLabel: onRetry != null ? 'Retry' : null,
      icon: Icons.error_outline_rounded,
    );
  }

  factory AppStateWidget.empty({
    Key? key,
    required String title,
    required String description,
    IconData icon = Icons.inbox_rounded,
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    return AppStateWidget(
      key: key,
      type: AppStateType.empty,
      title: title,
      description: description,
      icon: icon,
      onActionPressed: onActionPressed,
      actionLabel: actionLabel,
    );
  }

  factory AppStateWidget.offline({
    Key? key,
    VoidCallback? onRetry,
  }) {
    return AppStateWidget(
      key: key,
      type: AppStateType.offline,
      title: 'You are offline',
      description: 'Check your connection and try again.',
      icon: Icons.wifi_off_rounded,
      onActionPressed: onRetry,
      actionLabel: onRetry != null ? 'Retry' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData resolvedIcon;
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
        resolvedIcon = icon ?? Icons.error_outline_rounded;
        iconColor = AppTheme.errorColor;
        break;
      case AppStateType.empty:
        resolvedIcon = icon ?? Icons.inbox_rounded;
        iconColor = AppTheme.mutedTextColor;
        break;
      case AppStateType.success:
        resolvedIcon = icon ?? Icons.check_circle_outline_rounded;
        iconColor = AppTheme.tricolorGreen;
        break;
      case AppStateType.offline:
        resolvedIcon = icon ?? Icons.wifi_off_rounded;
        iconColor = AppTheme.accentColor;
        break;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(resolvedIcon, size: compact ? 48 : 64, color: iconColor),
            SizedBox(height: compact ? 14 : 20),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: compact ? 12.5 : 13,
                color: AppTheme.mutedTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              SizedBox(height: compact ? 16 : 24),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: Icon(
                  type == AppStateType.offline
                      ? Icons.refresh_rounded
                      : Icons.replay_rounded,
                  size: 18,
                ),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

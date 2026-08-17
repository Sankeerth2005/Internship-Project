import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AppSafeBottomMode {
  /// Pinned bar inside a Scaffold that already resizes for the keyboard.
  scaffold,

  /// Sheets / overlays that must clear both the keyboard and the system inset.
  overlay,
}

/// One source of bottom safe-area spacing for pinned action bars.
///
/// Does not restyle the child. Adds only the device inset so CTAs stay above
/// gesture indicators and 3-button Android navigation.
class AppSafeBottomBar extends StatelessWidget {
  final Widget child;
  final AppSafeBottomMode mode;
  final Color? fillColor;

  const AppSafeBottomBar({
    super.key,
    required this.child,
    this.mode = AppSafeBottomMode.scaffold,
    this.fillColor,
  });

  static double insetOf(
    BuildContext context, {
    AppSafeBottomMode mode = AppSafeBottomMode.scaffold,
  }) {
    final mq = MediaQuery.of(context);
    final viewPadding = mq.viewPadding.bottom;
    final keyboard = mq.viewInsets.bottom;
    switch (mode) {
      case AppSafeBottomMode.scaffold:
        return keyboard > 0 ? 0.0 : viewPadding;
      case AppSafeBottomMode.overlay:
        return math.max(keyboard, viewPadding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: EdgeInsets.only(bottom: insetOf(context, mode: mode)),
      child: child,
    );
    if (fillColor == null) return padded;
    return ColoredBox(color: fillColor!, child: padded);
  }
}

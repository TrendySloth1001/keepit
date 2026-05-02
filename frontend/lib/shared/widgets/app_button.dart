import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/sketch.dart';
import '../../app/theme/tokens.dart';

enum AppButtonVariant { primary, secondary, danger }

/// Standard CTA — replaced with the hand-drawn [SketchButton] look so
/// every action across the app reads as a sketchbook UI element.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isBusy = false,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isBusy;
  final AppButtonVariant variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final fill = switch (variant) {
      AppButtonVariant.primary => AppTheme.primary,
      AppButtonVariant.secondary => AppTheme.surface,
      AppButtonVariant.danger => AppTheme.surface,
    };
    final fg = switch (variant) {
      AppButtonVariant.primary => AppTheme.onPrimary,
      AppButtonVariant.secondary => AppTheme.fg,
      AppButtonVariant.danger => AppTheme.error,
    };
    final button = SizedBox(
      height: AppLayout.buttonHeight,
      width: fullWidth ? double.infinity : null,
      child: SketchButton(
        label: label,
        icon: icon,
        onPressed: onPressed,
        busy: isBusy,
        fullWidth: fullWidth,
        fill: fill,
        foreground: fg,
      ),
    );
    return button;
  }
}

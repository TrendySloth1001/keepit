import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

enum AppButtonVariant { primary, secondary, danger, accent }

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
    final (bg, fg, iconColor) = switch (variant) {
      AppButtonVariant.primary => (
          AppTheme.ink,
          AppTheme.white,
          AppTheme.primary,
        ),
      AppButtonVariant.accent => (
          AppTheme.primary,
          AppTheme.white,
          AppTheme.white,
        ),
      AppButtonVariant.danger => (
          AppTheme.error,
          AppTheme.white,
          AppTheme.white,
        ),
      AppButtonVariant.secondary => (
          AppTheme.surface,
          AppTheme.fg,
          AppTheme.fg,
        ),
    };

    if (variant == AppButtonVariant.secondary) {
      return SizedBox(
        height: AppLayout.buttonHeight,
        width: fullWidth ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: isBusy ? null : onPressed,
          icon: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (icon != null
                  ? Icon(icon, color: iconColor)
                  : const SizedBox.shrink()),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      height: AppLayout.buttonHeight,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        onPressed: isBusy ? null : onPressed,
        icon: isBusy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : (icon != null
                ? Icon(icon, color: iconColor, size: 18)
                : const SizedBox.shrink()),
        label: Text(label),
      ),
    );
  }
}

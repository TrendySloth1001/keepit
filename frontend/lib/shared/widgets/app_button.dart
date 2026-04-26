import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

enum AppButtonVariant { primary, secondary, danger }

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
    final child = isBusy
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppIconSize.md),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(fullWidth ? double.infinity : 0, AppLayout.buttonHeight),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(
            color: variant == AppButtonVariant.danger
                ? AppTheme.error
                : AppTheme.white,
          ),
        ),
      ),
      foregroundColor: WidgetStateProperty.all(
        switch (variant) {
          AppButtonVariant.primary => AppTheme.black,
          AppButtonVariant.secondary => AppTheme.white,
          AppButtonVariant.danger => AppTheme.error,
        },
      ),
      backgroundColor: WidgetStateProperty.all(
        switch (variant) {
          AppButtonVariant.primary => AppTheme.white,
          AppButtonVariant.secondary => AppTheme.black,
          AppButtonVariant.danger => AppTheme.black,
        },
      ),
    );

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        style: style,
        onPressed: isBusy ? null : onPressed,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        style: style,
        onPressed: isBusy ? null : onPressed,
        child: child,
      ),
      AppButtonVariant.danger => OutlinedButton(
        style: style,
        onPressed: isBusy ? null : onPressed,
        child: child,
      ),
    };

    return button;
  }
}

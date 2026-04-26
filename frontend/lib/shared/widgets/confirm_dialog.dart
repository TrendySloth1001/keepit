import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import 'app_button.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppTheme.black.withValues(alpha: 0.7),
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(
        message,
        style: const TextStyle(color: AppTheme.white, fontSize: AppType.body, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: cancelLabel,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: confirmLabel,
                variant: destructive
                    ? AppButtonVariant.danger
                    : AppButtonVariant.primary,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

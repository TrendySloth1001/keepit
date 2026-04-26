import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

enum AppSnackKind { success, error, info }

void showAppSnack(BuildContext context, String message, {AppSnackKind kind = AppSnackKind.info}) {
  final color = switch (kind) {
    AppSnackKind.success => AppTheme.success,
    AppSnackKind.error => AppTheme.error,
    AppSnackKind.info => AppTheme.white,
  };
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppTheme.black,
      content: Text(message, style: TextStyle(color: color, fontSize: AppType.body)),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(color: color),
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}

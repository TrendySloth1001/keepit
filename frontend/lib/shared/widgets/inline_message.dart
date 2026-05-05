import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';

enum InlineMessageKind { error, success, warning, info }

class InlineMessage extends StatelessWidget {
  const InlineMessage({super.key, required this.message, required this.kind});

  final String message;
  final InlineMessageKind kind;

  Color get _color => switch (kind) {
    InlineMessageKind.error => AppTheme.error,
    InlineMessageKind.success => AppTheme.success,
    InlineMessageKind.warning => AppTheme.warning,
    InlineMessageKind.info => AppTheme.info,
  };

  IconData get _icon => switch (kind) {
    InlineMessageKind.error => Icons.error_outline,
    InlineMessageKind.success => Icons.check_circle_outline,
    InlineMessageKind.warning => Icons.warning_amber_outlined,
    InlineMessageKind.info => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _color, size: AppIconSize.md),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: _color, fontSize: AppType.body),
            ),
          ),
        ],
      ),
    );
  }
}

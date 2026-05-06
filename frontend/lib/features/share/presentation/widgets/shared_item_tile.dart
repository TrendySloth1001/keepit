import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../../vault/data/icon_catalog.dart';
import '../../../vault/data/vault_models.dart';
import '../../data/share_models.dart';

class SharedItemTile extends StatelessWidget {
  const SharedItemTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onMore,
  });

  final SharedItem item;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  String get _typeLabel => switch (item.type) {
        VaultItemType.password => 'Password',
        VaultItemType.note => 'Note',
        VaultItemType.key => 'Key',
        VaultItemType.file => 'File',
        VaultItemType.image => 'Image',
      };

  @override
  Widget build(BuildContext context) {
    final iconKey = IconCatalog.guessFromTitle(item.title).key;
    final owner = item.ownerName.isEmpty ? item.ownerEmail : item.ownerName;
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                VaultIcon(iconKey: iconKey, size: 44),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.fg,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          const _SharePillLeading(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'From $owner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetaChip(label: _typeLabel),
                          _MetaChip(
                            label: 'Shared ${formatRelativeTime(item.createdAt)}',
                          ),
                          _MetaChip(
                            icon: item.canEdit
                                ? Icons.edit_outlined
                                : Icons.visibility_outlined,
                            label: item.canEdit ? 'Can edit' : 'View only',
                          ),
                          if (item.expiresAt != null)
                            _MetaChip(
                              icon: Icons.timer_outlined,
                              label: item.isExpired
                                  ? 'Expired'
                                  : 'Revokes in ${formatCountdown(item.expiresAt!)}',
                              tone: item.isExpired
                                  ? _MetaChipTone.danger
                                  : _MetaChipTone.warning,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onMore != null)
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.muted),
                    onPressed: onMore,
                  )
                else
                  const Icon(Icons.chevron_right, color: AppTheme.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SharePillLeading extends StatelessWidget {
  const _SharePillLeading();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.share_outlined, size: 11, color: AppTheme.primaryDark),
          SizedBox(width: 4),
          Text(
            'Shared',
            style: TextStyle(
              color: AppTheme.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

enum _MetaChipTone { neutral, warning, danger }

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.icon,
    this.tone = _MetaChipTone.neutral,
  });
  final String label;
  final IconData? icon;
  final _MetaChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _MetaChipTone.warning => (
          bg: AppTheme.warning.withValues(alpha: 0.14),
          fg: AppTheme.warning,
        ),
      _MetaChipTone.danger => (
          bg: AppTheme.error.withValues(alpha: 0.14),
          fg: AppTheme.error,
        ),
      _ => (bg: AppTheme.surfaceAlt, fg: AppTheme.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: colors.fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

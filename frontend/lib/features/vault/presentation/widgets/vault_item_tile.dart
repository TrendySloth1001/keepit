import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../data/icon_catalog.dart';
import '../../data/vault_models.dart';

class VaultItemTile extends StatelessWidget {
  const VaultItemTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  final VaultItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  String get _typeLabel => switch (item.type) {
        VaultItemType.password => 'Password',
        VaultItemType.note => 'Note',
        VaultItemType.key => 'Key',
        VaultItemType.file => 'File',
        VaultItemType.image => 'Image',
      };

  IconData get _typeFallback => switch (item.type) {
        VaultItemType.password => Icons.password,
        VaultItemType.note => Icons.sticky_note_2_outlined,
        VaultItemType.key => Icons.vpn_key,
        VaultItemType.file => Icons.attach_file,
        VaultItemType.image => Icons.image_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final size = item.fileSize;
    final pending = item.uploadStatus == 'pending';
    // For passwords/keys we try to brand-match from title; for files/images
    // we keep the type-based icon since titles tend to be filenames.
    final useBrand = item.type == VaultItemType.password ||
        item.type == VaultItemType.key ||
        item.type == VaultItemType.note;
    final guessed = useBrand ? IconCatalog.guessFromTitle(item.title) : null;

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (guessed != null && guessed.key != 'generic')
                  VaultIcon(iconKey: guessed.key, size: 44)
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      _typeFallback,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.fg,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          _typeLabel,
                          if (size != null) formatBytes(size),
                          formatRelativeTime(item.updatedAt),
                          if (pending) 'pending',
                        ].join(' · '),
                        style: TextStyle(
                          color: pending ? AppTheme.warning : AppTheme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

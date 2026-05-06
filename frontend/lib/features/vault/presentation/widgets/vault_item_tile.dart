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

  String? _prettyMime(String? mime) {
    if (mime == null || mime.isEmpty) return null;
    final lower = mime.toLowerCase();
    if (!lower.contains('/')) return lower.toUpperCase();
    final suffix = lower.split('/').last.trim();
    if (suffix.isEmpty) return null;
    return suffix.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = item.fileSize;
    final pending = item.uploadStatus == 'pending';
    final isFile =
        item.type == VaultItemType.file || item.type == VaultItemType.image;
    final mimeLabel = isFile ? _prettyMime(item.fileMime) : null;
    // For passwords/keys we try to brand-match from title; for files/images
    // we keep the type-based icon since titles tend to be filenames.
    final useBrand =
        item.type == VaultItemType.password ||
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
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _MetaChip(label: _typeLabel),
                          _MetaChip(
                            label:
                                'Updated ${formatRelativeTime(item.updatedAt)}',
                          ),
                          if (pending)
                            const _MetaChip(
                              label: 'Uploading',
                              tone: _MetaChipTone.warning,
                            ),
                          if (size != null) _MetaChip(label: formatBytes(size)),
                          if (mimeLabel != null) _MetaChip(label: mimeLabel),
                          if (!isFile) const _MetaChip(label: 'Encrypted'),
                        ],
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

enum _MetaChipTone { neutral, warning }

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.tone = _MetaChipTone.neutral});

  final String label;
  final _MetaChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _MetaChipTone.warning => (
        bg: AppTheme.warning.withValues(alpha: 0.14),
        fg: AppTheme.warning,
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
      child: Text(
        label,
        style: TextStyle(
          color: colors.fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

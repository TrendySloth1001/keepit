import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
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

  IconData get _icon => switch (item.type) {
    VaultItemType.password => Icons.password,
    VaultItemType.note => Icons.notes,
    VaultItemType.key => Icons.key,
    VaultItemType.file => Icons.attach_file,
    VaultItemType.image => Icons.image_outlined,
  };

  String get _typeLabel => switch (item.type) {
    VaultItemType.password => 'Password',
    VaultItemType.note => 'Note',
    VaultItemType.key => 'Key',
    VaultItemType.file => 'File',
    VaultItemType.image => 'Image',
  };

  @override
  Widget build(BuildContext context) {
    final size = item.fileSize;
    final pending = item.uploadStatus == 'pending';
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: AppRadius.brLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.black,
          border: Border.all(color: AppTheme.white),
          borderRadius: AppRadius.brLg,
        ),
        child: Row(
          children: [
            Container(
              width: AppLayout.avatarMd,
              height: AppLayout.avatarMd,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.white),
              ),
              child: Icon(_icon, color: AppTheme.white, size: AppIconSize.md),
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
                      color: AppTheme.white,
                      fontSize: AppType.body,
                      fontWeight: FontWeight.w700,
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
                      color: pending ? AppTheme.warning : AppTheme.white,
                      fontSize: AppType.micro,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.white),
          ],
        ),
      ),
    );
  }
}

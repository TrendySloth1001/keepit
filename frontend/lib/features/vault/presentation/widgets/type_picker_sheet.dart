import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../data/vault_models.dart';

Future<VaultItemType?> showTypePicker(BuildContext context) {
  return showModalBottomSheet<VaultItemType>(
    context: context,
    backgroundColor: AppTheme.black,
    builder: (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New item',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: AppType.subtitle,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final entry in const [
              (VaultItemType.password, 'Password', Icons.password,
                  'Username, password, URL, notes'),
              (VaultItemType.note, 'Secure note', Icons.notes,
                  'Encrypted long-form note'),
              (VaultItemType.key, 'API key / token', Icons.key,
                  'Tokens, recovery codes, secrets'),
              (VaultItemType.image, 'Image', Icons.image_outlined,
                  'Encrypt and store an image'),
              (VaultItemType.file, 'File', Icons.attach_file,
                  'Encrypt and store any file'),
            ])
              _TypeRow(
                type: entry.$1,
                title: entry.$2,
                icon: entry.$3,
                subtitle: entry.$4,
              ),
          ],
        ),
      ),
    ),
  );
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  final VaultItemType type;
  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(type),
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: AppLayout.avatarSm,
              height: AppLayout.avatarSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.white),
              ),
              child: Icon(icon, color: AppTheme.white, size: AppIconSize.sm),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: AppType.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.white,
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

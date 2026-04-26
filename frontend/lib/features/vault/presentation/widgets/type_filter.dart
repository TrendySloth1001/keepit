import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../data/vault_models.dart';

class TypeFilter extends StatelessWidget {
  const TypeFilter({super.key, required this.value, required this.onChanged});

  final VaultItemType? value;
  final ValueChanged<VaultItemType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = <(VaultItemType?, String, IconData)>[
      (null, 'All', Icons.apps_outlined),
      (VaultItemType.password, 'Passwords', Icons.password),
      (VaultItemType.note, 'Notes', Icons.notes),
      (VaultItemType.key, 'Keys', Icons.key),
      (VaultItemType.image, 'Images', Icons.image_outlined),
      (VaultItemType.file, 'Files', Icons.attach_file),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final (type, label, icon) = entries[i];
          final selected = type == value;
          return InkWell(
            onTap: () => onChanged(type),
            borderRadius: AppRadius.brPill,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected ? AppTheme.white : AppTheme.black,
                border: Border.all(color: AppTheme.white),
                borderRadius: AppRadius.brPill,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: AppIconSize.sm,
                    color: selected ? AppTheme.black : AppTheme.white,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppTheme.black : AppTheme.white,
                      fontSize: AppType.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

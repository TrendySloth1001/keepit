import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/sketch.dart';
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
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final (type, label, icon) = entries[i];
          final selected = type == value;
          // Alternating tilt so chips sit slightly out-of-square.
          final tilt = (i.isEven ? 1 : -1) * 0.01;
          return Transform.rotate(
            angle: tilt,
            child: InkWell(
              onTap: () => onChanged(type),
              borderRadius: AppRadius.brPill,
              child: SketchBox(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                radius: 999,
                fill: selected ? AppTheme.primary : AppTheme.surface,
                hatchColor:
                    selected ? AppTheme.onPrimary.withValues(alpha: 0.20) : null,
                hatchSpacing: 5,
                seed: label.hashCode,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: AppIconSize.sm,
                      color: selected ? AppTheme.onPrimary : AppTheme.fg,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? AppTheme.onPrimary : AppTheme.fg,
                        fontSize: AppType.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

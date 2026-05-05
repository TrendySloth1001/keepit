import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../data/vault_models.dart';

class TypePickerSheet extends StatelessWidget {
  const TypePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: const Text(
              'Add Item',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.fg,
              ),
            ),
          ),
          _TypeTile(
            type: VaultItemType.password,
            icon: Icons.password,
            label: 'Password',
            desc: 'Save login credentials',
          ),
          _TypeTile(
            type: VaultItemType.note,
            icon: Icons.notes,
            label: 'Secure Note',
            desc: 'Write text encrypted',
          ),
          _TypeTile(
            type: VaultItemType.file,
            icon: Icons.attach_file,
            label: 'File',
            desc: 'Upload a document',
          ),
          _TypeTile(
            type: VaultItemType.image,
            icon: Icons.image_outlined,
            label: 'Image',
            desc: 'Upload a photo',
          ),
          // Exclude keys for now — they're created during setup.
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.icon,
    required this.label,
    required this.desc,
  });

  final VaultItemType type;
  final IconData icon;
  final String label;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context, type),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.fg,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<VaultItemType?> showTypePicker(BuildContext context) {
  return showModalBottomSheet<VaultItemType>(
    context: context,
    builder: (context) => const TypePickerSheet(),
  );
}

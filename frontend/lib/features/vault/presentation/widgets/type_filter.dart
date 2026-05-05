import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../data/vault_models.dart';

class TypeFilter extends StatelessWidget {
  const TypeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final VaultItemType? selected;
  final ValueChanged<VaultItemType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _Chip(
            icon: Icons.dashboard_outlined,
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          ...VaultItemType.values.map(
            (t) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: _Chip(
                icon: _iconFor(t),
                label: _labelFor(t),
                selected: selected == t,
                onTap: () => onChanged(t),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(VaultItemType t) => switch (t) {
        VaultItemType.password => 'Passwords',
        VaultItemType.note => 'Notes',
        VaultItemType.key => 'Keys',
        VaultItemType.file => 'Files',
        VaultItemType.image => 'Images',
      };

  IconData _iconFor(VaultItemType t) => switch (t) {
        VaultItemType.password => Icons.password,
        VaultItemType.note => Icons.sticky_note_2_outlined,
        VaultItemType.key => Icons.vpn_key_outlined,
        VaultItemType.file => Icons.description_outlined,
        VaultItemType.image => Icons.image_outlined,
      };
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.short,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppTheme.ink : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: selected ? AppTheme.ink : AppTheme.hairline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppTheme.primary : AppTheme.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.white : AppTheme.fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

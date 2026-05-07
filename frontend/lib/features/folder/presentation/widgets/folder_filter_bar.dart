import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../folder_notifier.dart';

/// Horizontal chip strip of folders. Tap to filter the vault list, long-press
/// for rename/delete, tap "+" to create. The "All" chip clears the filter.
class FolderFilterBar extends ConsumerWidget {
  const FolderFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// `null` → All. `'none'` → Uncategorized. Else a folder id.
  final String? selected;
  final ValueChanged<String?> onChanged;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'New folder',
          style: TextStyle(color: AppTheme.fg),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      final folder =
          await ref.read(folderProvider.notifier).create(name: name);
      if (!context.mounted) return;
      onChanged(folder.id);
    } catch (e) {
      if (!context.mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  Future<void> _manage(
    BuildContext context,
    WidgetRef ref,
    String folderId,
    String currentName,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppTheme.fg),
            title: const Text(
              'Rename folder',
              style: TextStyle(color: AppTheme.fg),
            ),
            onTap: () => Navigator.pop(ctx, 'rename'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppTheme.error),
            title: const Text(
              'Delete folder',
              style: TextStyle(color: AppTheme.error),
            ),
            subtitle: const Text(
              'Items in this folder become uncategorized — '
              'they are not deleted.',
              style: TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ]),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'rename') {
      final controller = TextEditingController(text: currentName);
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Rename folder',
            style: TextStyle(color: AppTheme.fg),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 80,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (name == null || name.isEmpty || !context.mounted) return;
      try {
        await ref.read(folderProvider.notifier).rename(folderId, name);
      } catch (e) {
        if (!context.mounted) return;
        showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
      }
      return;
    }
    if (action == 'delete') {
      try {
        await ref.read(folderProvider.notifier).delete(folderId);
        if (selected == folderId) onChanged(null);
      } catch (e) {
        if (!context.mounted) return;
        showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(folderProvider);
    final folders = state.folders;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _Chip(
            label: 'All',
            icon: Icons.all_inbox_outlined,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 6),
          _Chip(
            label: 'Uncategorized',
            icon: Icons.label_off_outlined,
            selected: selected == 'none',
            onTap: () => onChanged('none'),
          ),
          for (final f in folders) ...[
            const SizedBox(width: 6),
            _Chip(
              label: f.name,
              icon: Icons.folder_outlined,
              count: f.itemCount,
              selected: selected == f.id,
              onTap: () => onChanged(f.id),
              onLongPress: () => _manage(context, ref, f.id, f.name),
            ),
          ],
          const SizedBox(width: 6),
          _Chip(
            label: 'New',
            icon: Icons.add,
            selected: false,
            tone: _ChipTone.accent,
            onTap: () => _create(context, ref),
          ),
        ],
      ),
    );
  }
}

enum _ChipTone { neutral, accent }

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.count,
    this.onLongPress,
    this.tone = _ChipTone.neutral,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final int? count;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppTheme.primary
        : (tone == _ChipTone.accent
            ? AppTheme.primary.withValues(alpha: 0.12)
            : AppTheme.surfaceAlt);
    final fg = selected
        ? Colors.white
        : (tone == _ChipTone.accent ? AppTheme.primary : AppTheme.fg);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

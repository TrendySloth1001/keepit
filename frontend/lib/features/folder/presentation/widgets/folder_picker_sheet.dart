import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../folder_notifier.dart';

/// A bottom sheet that lets the user move an item to a folder, clear the
/// folder link ("uncategorize"), or create a new folder inline.
///
/// Returns the chosen folder id, the literal `''` to clear the folder, or
/// `null` if the sheet was dismissed without a selection.
Future<String?> showFolderPickerSheet(
  BuildContext context, {
  String? currentFolderId,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    backgroundColor: AppTheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _FolderPickerSheet(currentFolderId: currentFolderId),
  );
}

class _FolderPickerSheet extends ConsumerStatefulWidget {
  const _FolderPickerSheet({required this.currentFolderId});
  final String? currentFolderId;

  @override
  ConsumerState<_FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends ConsumerState<_FolderPickerSheet> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(folderProvider.notifier).refresh();
    });
  }

  Future<void> _createNew() async {
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
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final folder = await ref
          .read(folderProvider.notifier)
          .create(name: name);
      if (!mounted) return;
      Navigator.of(context).pop<String?>(folder.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnack(
        context,
        friendlyApiError(e),
        kind: AppSnackKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(folderProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Move to folder',
              style: TextStyle(
                color: AppTheme.fg,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Row(
              icon: Icons.label_off_outlined,
              label: 'Uncategorized',
              selected: widget.currentFolderId == null,
              onTap: () => Navigator.pop(context, ''),
            ),
            const Divider(color: AppTheme.hairline, height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: state.folders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Text(
                        state.isLoading
                            ? 'Loading folders…'
                            : 'No folders yet — create one below.',
                        style: const TextStyle(color: AppTheme.muted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.folders.length,
                      separatorBuilder: (_, _) => const Divider(
                        color: AppTheme.hairline,
                        height: 1,
                      ),
                      itemBuilder: (_, i) {
                        final f = state.folders[i];
                        return _Row(
                          icon: Icons.folder_outlined,
                          label: f.name,
                          subtitle: '${f.itemCount} item'
                              '${f.itemCount == 1 ? '' : 's'}',
                          selected: f.id == widget.currentFolderId,
                          onTap: () => Navigator.pop(context, f.id),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Create new folder',
              icon: Icons.create_new_folder_outlined,
              variant: AppButtonVariant.secondary,
              isBusy: _busy,
              onPressed: _busy ? null : _createNew,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.muted, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

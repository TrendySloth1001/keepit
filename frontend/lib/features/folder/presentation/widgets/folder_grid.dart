import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../collab_folder/data/collab_folder_models.dart';
import '../../../collab_folder/presentation/collab_folder_notifier.dart';
import '../../../share/data/share_models.dart';
import '../../../share/presentation/share_notifier.dart';
import '../../data/folder_models.dart';
import '../folder_notifier.dart';
import 'folder_edit_sheet.dart';
import 'folder_icons.dart';

/// Finder-style grid of folders. Tap a folder to open its detail page,
/// long-press for share/rename/delete, or tap "New" to create one.
class FolderGrid extends ConsumerWidget {
  const FolderGrid({
    super.key,
    required this.onOpen,
    required this.onShare,
    this.onOpenSharedBundle,
    this.onOpenCollab,
    this.onCreateCollab,
  });

  final ValueChanged<VaultFolder> onOpen;
  final ValueChanged<VaultFolder> onShare;

  /// Tapping a shared-folder tile fires this. The bundle is the list of
  /// SharedItem rows that belong to the same shared snapshot.
  final ValueChanged<List<SharedItem>>? onOpenSharedBundle;

  /// Tapping a collaborative folder routes to its detail page.
  final ValueChanged<CollabFolderSummary>? onOpenCollab;

  /// Optional handler for the "+ Shared folder" action. Called when the
  /// user taps the "shared folder" entry in the create menu.
  final VoidCallback? onCreateCollab;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showFolderEditSheet(
      context,
      title: 'New folder',
      confirm: 'Create',
    );
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(folderProvider.notifier)
          .create(name: result.name, iconKey: result.iconKey);
    } catch (e) {
      if (!context.mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  Future<void> _editFolder(
    BuildContext context,
    WidgetRef ref,
    VaultFolder folder,
  ) async {
    final result = await showFolderEditSheet(
      context,
      title: 'Edit folder',
      confirm: 'Save',
      initialName: folder.name,
      initialIconKey: folder.iconKey,
    );
    if (result == null || !context.mounted) return;
    try {
      final notifier = ref.read(folderProvider.notifier);
      if (result.name != folder.name) {
        await notifier.rename(folder.id, result.name);
      }
      if (result.iconKey != folder.iconKey) {
        await notifier.setIcon(folder.id, result.iconKey);
      }
    } catch (e) {
      if (!context.mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  Future<void> _manage(
    BuildContext context,
    WidgetRef ref,
    VaultFolder folder,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Open folder'),
            onTap: () => Navigator.pop(ctx, 'open'),
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared_outlined),
            title: const Text('Share folder'),
            subtitle: const Text(
              'Send a sealed snapshot to another KeepIt user.',
            ),
            onTap: () => Navigator.pop(ctx, 'share'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit name & icon'),
            onTap: () => Navigator.pop(ctx, 'edit'),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(ctx).colorScheme.error,
            ),
            title: Text(
              'Delete folder',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
            subtitle: const Text(
              'Items inside become uncategorized — they are not deleted.',
            ),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ]),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'open':
        onOpen(folder);
      case 'share':
        onShare(folder);
      case 'edit':
        await _editFolder(context, ref, folder);
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete "${folder.name}"?'),
            content: const Text(
              'Items inside will become uncategorized. Nothing is deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.onErrorContainer,
                  backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        try {
          await ref.read(folderProvider.notifier).delete(folder.id);
        } catch (e) {
          if (!context.mounted) return;
          showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
        }
    }
  }

  Future<void> _showCreateMenu(BuildContext context, WidgetRef ref) async {
    if (onCreateCollab == null) {
      await _create(context, ref);
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined),
            title: const Text('New folder'),
            subtitle: const Text(
              'Personal folder for organizing your own items.',
            ),
            onTap: () => Navigator.pop(ctx, 'solo'),
          ),
          ListTile(
            leading: const Icon(Icons.group_add_outlined),
            title: const Text('New shared folder'),
            subtitle: const Text(
              'Invite people to add credentials together.',
            ),
            onTap: () => Navigator.pop(ctx, 'collab'),
          ),
        ]),
      ),
    );
    if (action == 'solo') {
      if (!context.mounted) return;
      await _create(context, ref);
    } else if (action == 'collab') {
      onCreateCollab?.call();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(folderProvider);
    final folders = state.folders;
    final shareState = ref.watch(shareProvider);
    final sharedBundles = _groupSharedBundles(shareState.received);
    final collabState = ref.watch(collabFolderListProvider);
    final collabFolders = collabState.folders;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Folders',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCreateMenu(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (folders.isEmpty &&
              sharedBundles.isEmpty &&
              collabFolders.isEmpty)
            _EmptyHint(onCreate: () => _showCreateMenu(context, ref))
          else
            Column(
              children: [
                for (final folder in folders) ...[
                  _FolderRow(
                    folder: folder,
                    onTap: () => onOpen(folder),
                    onLongPress: () => _manage(context, ref, folder),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                for (final cf in collabFolders) ...[
                  _CollabFolderRow(
                    folder: cf,
                    onTap: () => onOpenCollab?.call(cf),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                for (final bundle in sharedBundles) ...[
                  _SharedBundleRow(
                    bundle: bundle,
                    onTap: () => onOpenSharedBundle?.call(bundle),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CollabFolderRow extends StatelessWidget {
  const _CollabFolderRow({required this.folder, required this.onTap});
  final CollabFolderSummary folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.tertiaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FolderGlyph(
                    iconKey: folder.iconKey,
                    size: 36,
                    foreground: cs.tertiary,
                    innerColor: cs.onTertiary,
                  ),
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.tertiaryContainer,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: 11,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onTertiaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${folder.isOwner ? "You own" : "Shared by ${folder.ownerName}"}'
                      ' • ${folder.memberCount} '
                      '${folder.memberCount == 1 ? "member" : "members"}'
                      ' • ${folder.itemCount} '
                      '${folder.itemCount == 1 ? "item" : "items"}',
                      style: TextStyle(
                        color: cs.onTertiaryContainer.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onTertiaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Groups received SharedItem rows by bundleId. Singles (bundleId == null)
/// are skipped — they live in the items list.
List<List<SharedItem>> _groupSharedBundles(List<SharedItem> received) {
  final byId = <String, List<SharedItem>>{};
  for (final s in received) {
    final id = s.bundleId;
    if (id == null) continue;
    byId.putIfAbsent(id, () => []).add(s);
  }
  return byId.values.toList()
    ..sort((a, b) => b.first.createdAt.compareTo(a.first.createdAt));
}

class _SharedBundleRow extends StatelessWidget {
  const _SharedBundleRow({required this.bundle, required this.onTap});
  final List<SharedItem> bundle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = bundle.first.bundleName ?? 'Shared folder';
    final owner = bundle.first.ownerName.isNotEmpty
        ? bundle.first.ownerName
        : bundle.first.ownerEmail;
    final count = bundle.length;
    return Material(
      color: cs.secondaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FolderGlyph(
                    iconKey: 'folder',
                    size: 36,
                    foreground: cs.secondary,
                    innerColor: cs.onSecondary,
                  ),
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.secondaryContainer,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: 11,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shared by $owner • '
                      '${count == 1 ? "1 item" : "$count items"}',
                      style: TextStyle(
                        color: cs.onSecondaryContainer.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.folder,
    required this.onTap,
    required this.onLongPress,
  });

  final VaultFolder folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              FolderGlyph(
                iconKey: folder.iconKey,
                size: 36,
                foreground: cs.primary,
                innerColor: cs.onPrimary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      folder.itemCount == 1
                          ? '1 item'
                          : '${folder.itemCount} items',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onCreate,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.create_new_folder_outlined,
                  color: cs.primary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organize with folders',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Create folders like Office, Workplace, or '
                      'Entertainment to group related items.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

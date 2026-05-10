import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../share/presentation/widgets/share_folder_sheet.dart';
import '../../../vault/data/vault_models.dart';
import '../../../vault/presentation/vault_notifier.dart';
import '../../../vault/presentation/widgets/auto_lock_scope.dart';
import '../../../vault/presentation/widgets/type_picker_sheet.dart';
import '../../../vault/presentation/widgets/vault_item_tile.dart';
import '../../data/folder_models.dart';
import '../folder_notifier.dart';
import '../widgets/folder_edit_sheet.dart';
import '../widgets/folder_icons.dart';

/// Finder-style detail page for a folder. Shows the items inside, a header
/// with rename/share/delete actions, and a FAB to add new items that land
/// directly in this folder.
class FolderDetailPage extends ConsumerStatefulWidget {
  const FolderDetailPage({super.key, required this.folder});
  final VaultFolder folder;

  @override
  ConsumerState<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends ConsumerState<FolderDetailPage> {
  final _scrollController = ScrollController();
  late VaultFolder _folder;

  @override
  void initState() {
    super.initState();
    _folder = widget.folder;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Scope the global vault list to this folder. We restore it to
      // 'none' (uncategorized) on dispose so home keeps showing loose items.
      ref.read(vaultProvider.notifier).setFolderFilter(_folder.id);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Restore the global vault list to "uncategorized" so the home page
    // shows loose items again. Read via ref is fine here since the provider
    // outlives the route.
    try {
      ref.read(vaultProvider.notifier).setFolderFilter('none');
    } catch (_) {}
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(vaultProvider.notifier).loadMore();
    }
  }

  Future<void> _onAdd() async {
    final type = await showTypePicker(context);
    if (type == null || !mounted) return;
    // The editors don't accept a target folder yet, so we capture the new
    // item id by snapshotting the list, navigating to the editor, then
    // moving any newly-created item into this folder when we return.
    final beforeIds = ref
        .read(vaultProvider)
        .items
        .map((i) => i.id)
        .toSet();
    switch (type) {
      case VaultItemType.password:
        await context.push('/vault/edit/password');
      case VaultItemType.note:
        await context.push('/vault/edit/note');
      case VaultItemType.key:
        await context.push('/vault/edit/key');
      case VaultItemType.file:
        await context.push('/vault/upload/file');
      case VaultItemType.image:
        await context.push('/vault/upload/image');
    }
    if (!mounted) return;
    final notifier = ref.read(vaultProvider.notifier);
    final created = ref
        .read(vaultProvider)
        .items
        .where((i) => !beforeIds.contains(i.id))
        .toList();
    for (final item in created) {
      if (item.folderId != _folder.id) {
        try {
          await notifier.moveToFolder(item, _folder.id);
          ref.read(folderProvider.notifier).bumpItemCount(_folder.id, 1);
        } catch (_) {
          // Non-fatal; item still exists outside the folder.
        }
      }
    }
  }

  void _onTap(VaultItem item) {
    switch (item.type) {
      case VaultItemType.password:
      case VaultItemType.note:
      case VaultItemType.key:
        context.push('/vault/view', extra: item);
      case VaultItemType.file:
      case VaultItemType.image:
        context.push('/vault/file', extra: item);
    }
  }

  Future<void> _edit() async {
    final result = await showFolderEditSheet(
      context,
      title: 'Edit folder',
      confirm: 'Save',
      initialName: _folder.name,
      initialIconKey: _folder.iconKey,
    );
    if (result == null || !mounted) return;
    try {
      final notifier = ref.read(folderProvider.notifier);
      var next = _folder;
      if (result.name != _folder.name) {
        await notifier.rename(_folder.id, result.name);
        next = next.copyWith(name: result.name);
      }
      if (result.iconKey != _folder.iconKey) {
        await notifier.setIcon(_folder.id, result.iconKey);
        next = next.copyWith(iconKey: result.iconKey);
      }
      if (mounted) setState(() => _folder = next);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${_folder.name}"?'),
        content: const Text(
          'Items inside become uncategorized. Nothing is deleted.',
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
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(folderProvider.notifier).delete(_folder.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  Future<void> _share() async {
    await showShareFolderSheet(context, folder: _folder);
  }

  Future<void> _moveOut(VaultItem item) async {
    try {
      await ref.read(vaultProvider.notifier).moveToFolder(item, null);
      ref.read(folderProvider.notifier).bumpItemCount(_folder.id, -1);
      if (!mounted) return;
      showAppSnack(
        context,
        'Moved "${item.title}" out of "${_folder.name}".',
        kind: AppSnackKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, friendlyApiError(e), kind: AppSnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultProvider);
    final cs = Theme.of(context).colorScheme;
    // Only items that actually belong to this folder. The vault notifier
    // is shared across pages, so a stale snapshot from elsewhere can briefly
    // bleed in until refresh completes — this filter keeps the UI honest.
    final items = state.visibleItems
        .where((i) => i.folderId == _folder.id)
        .toList();

    return AutoLockScope(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add to folder'),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(vaultProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar.large(
                  pinned: true,
                  expandedHeight: 120,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FolderGlyph(
                        iconKey: _folder.iconKey,
                        size: 28,
                        foreground: cs.primary,
                        innerColor: cs.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _folder.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Share folder',
                      icon: const Icon(Icons.folder_shared_outlined),
                      onPressed: _share,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) async {
                        if (v == 'edit') await _edit();
                        if (v == 'delete') await _delete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit name & icon'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (state.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: InlineMessage(
                        message: state.errorMessage!,
                        kind: InlineMessageKind.error,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      items.isEmpty && !state.isLoading
                          ? 'No items in this folder yet.'
                          : '${items.length} item${items.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (state.isLoading && items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: ShimmerCentered(),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.huge),
                      child: EmptyState(
                        icon: Icons.folder_open_outlined,
                        title: 'Folder is empty',
                        message:
                            'Tap "Add to folder" or move existing items into '
                            '"${_folder.name}".',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      96,
                    ),
                    sliver: SliverList.separated(
                      itemCount: items.length + (state.isPaging ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        if (i >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Center(
                              child: ShimmerBox(
                                width: 120,
                                height: 12,
                                borderRadius: 6,
                              ),
                            ),
                          );
                        }
                        final item = items[i];
                        return VaultItemTile(
                          item: item,
                          onTap: () => _onTap(item),
                          onLongPress: () => _moveOut(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


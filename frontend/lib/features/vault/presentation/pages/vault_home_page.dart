import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../../collab_folder/presentation/collab_folder_notifier.dart';
import '../../../folder/data/folder_models.dart';
import '../../../folder/presentation/folder_notifier.dart';
import '../../../folder/presentation/widgets/folder_grid.dart';
import '../../../folder/presentation/widgets/folder_edit_sheet.dart';
import '../../../share/data/share_models.dart';
import '../../../share/presentation/widgets/share_folder_sheet.dart';
import '../../../share/presentation/share_notifier.dart';
import '../../../share/presentation/widgets/shared_item_tile.dart';
import '../../data/vault_models.dart';
import '../storage_notifier.dart';
import '../vault_notifier.dart';
import '../widgets/auto_lock_scope.dart';
import '../widgets/storage_meter.dart';
import '../widgets/type_filter.dart';
import '../widgets/type_picker_sheet.dart';
import '../widgets/vault_item_tile.dart';

class VaultHomePage extends ConsumerStatefulWidget {
  const VaultHomePage({super.key});

  @override
  ConsumerState<VaultHomePage> createState() => _VaultHomePageState();
}

class _VaultHomePageState extends ConsumerState<VaultHomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Home shows ALL items (loose + foldered) so users never lose sight of
      // a credential just because it's been categorized. Folders sit on top
      // as a navigational shortcut.
      ref.read(vaultProvider.notifier).setFolderFilter(null);
      ref.read(vaultProvider.notifier).refresh();
      ref.read(storageProvider.notifier).refresh();
      ref.read(folderProvider.notifier).refresh();
      ref.read(collabFolderListProvider.notifier).refresh();
      // Lazily publish the user's sharing keypair so they can receive shares
      // from this point on. Failure is non-fatal — they just can't share yet.
      ref.read(shareProvider.notifier).ensureKeypair();
      ref.read(shareProvider.notifier).refresh();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
    switch (type) {
      case VaultItemType.password:
        context.push('/vault/edit/password');
        break;
      case VaultItemType.note:
        context.push('/vault/edit/note');
        break;
      case VaultItemType.key:
        context.push('/vault/edit/key');
        break;
      case VaultItemType.file:
        context.push('/vault/upload/file');
        break;
      case VaultItemType.image:
        context.push('/vault/upload/image');
        break;
    }
  }

  void _onTap(VaultItem item) {
    switch (item.type) {
      case VaultItemType.password:
      case VaultItemType.note:
      case VaultItemType.key:
        context.push('/vault/view', extra: item);
        break;
      case VaultItemType.file:
      case VaultItemType.image:
        context.push('/vault/file', extra: item);
        break;
    }
  }

  void _openFolder(VaultFolder folder) {
    context.push('/vault/folder', extra: folder);
  }

  Future<void> _shareFolder(VaultFolder folder) {
    return showShareFolderSheet(context, folder: folder);
  }

  Future<void> _createCollabFolder() async {
    final result = await showFolderEditSheet(
      context,
      title: 'New shared folder',
      confirm: 'Create',
    );
    if (result == null || !mounted) return;
    try {
      final created = await ref
          .read(collabFolderListProvider.notifier)
          .create(name: result.name, iconKey: result.iconKey);
      if (!mounted) return;
      context.push('/vault/collab/${created.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create folder: $e')),
      );
    }
  }

  void _openShared(SharedItem item) {
    context.push(
      '/vault/shared/view',
      extra: SharedItemViewArgs(item: item, incoming: true),
    );
  }

  List<SharedItem> _filterShared(
    List<SharedItem> items,
    VaultItemType? typeFilter,
    String search,
  ) {
    // Bundled shares (folder-shares) are surfaced as tiles in the FolderGrid,
    // not in the items list — exclude them here so a folder-share doesn't
    // appear twice.
    var filtered = items.where((i) => i.bundleId == null).toList();
    if (typeFilter != null) {
      filtered = filtered.where((i) => i.type == typeFilter).toList();
    }
    if (search.trim().isEmpty) return filtered;
    final q = search.toLowerCase();
    return filtered.where((i) => i.title.toLowerCase().contains(q)).toList();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultProvider);
    final notifier = ref.read(vaultProvider.notifier);
    final shareState = ref.watch(shareProvider);
    final user = ref.watch(authProvider).user;
    final firstName = (user?.name ?? '').split(' ').first;
    final sharedItems = _filterShared(
      shareState.received,
      state.typeFilter,
      state.search,
    );
    final totalVisible = state.visibleItems.length + sharedItems.length;

    return AutoLockScope(
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onAdd,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            onRefresh: () async {
              await notifier.refresh();
              await ref.read(storageProvider.notifier).refresh();
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _Hero(
                    greeting: _greeting(),
                    firstName: firstName,
                    avatarUrl: user?.avatarUrl,
                    onLock: () => ref.read(authProvider.notifier).lock(),
                    onSettings: () => context.push('/vault/settings'),
                    searchController: _searchController,
                    onSearch: notifier.setSearch,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: StorageMeter(
                      onUpgrade: () => context.push('/vault/upgrade'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FolderGrid(
                    onOpen: _openFolder,
                    onShare: _shareFolder,
                    onOpenSharedBundle: (_) => context.push('/vault/shared'),
                    onOpenCollab: (cf) =>
                        context.push('/vault/collab/${cf.id}'),
                    onCreateCollab: _createCollabFolder,
                  ),
                ),
                SliverToBoxAdapter(
                  child: TypeFilter(
                    selected: state.typeFilter,
                    onChanged: notifier.setTypeFilter,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.sm),
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
                _SectionHeader(
                  title: state.typeFilter == null
                      ? 'All items'
                      : 'Filtered items',
                  subtitle: '$totalVisible entries',
                ),
                if (state.isLoading && sharedItems.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: ShimmerCentered(),
                  )
                else if (totalVisible == 0)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.huge),
                      child: EmptyState(
                        icon: Icons.lock_outline,
                        title: state.search.isEmpty && state.typeFilter == null
                            ? 'Your vault is empty'
                            : 'No matching items',
                        message:
                            state.search.isEmpty && state.typeFilter == null
                            ? 'Tap + to add your first encrypted item.'
                            : 'Try a different search or filter.',
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
                      itemCount: totalVisible + (state.isPaging ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        if (i < sharedItems.length) {
                          final shared = sharedItems[i];
                          return SharedItemTile(
                            item: shared,
                            onTap: () => _openShared(shared),
                          );
                        }
                        final items = state.visibleItems;
                        final idx = i - sharedItems.length;
                        if (idx >= items.length) {
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
                        final item = items[idx];
                        return VaultItemTile(
                          item: item,
                          onTap: () => _onTap(item),
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.greeting,
    required this.firstName,
    required this.avatarUrl,
    required this.onLock,
    required this.onSettings,
    required this.searchController,
    required this.onSearch,
  });

  final String greeting;
  final String firstName;
  final String? avatarUrl;
  final VoidCallback onLock;
  final VoidCallback onSettings;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/logo/wallet-passes-app-logo.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'KeepIt',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Lock',
                onPressed: onLock,
                icon: const Icon(Icons.lock_outline),
              ),
              const SizedBox(width: AppSpacing.xs),
              InkWell(
                onTap: onSettings,
                borderRadius: BorderRadius.circular(40),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primary,
                  backgroundImage:
                      (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? NetworkImage(avatarUrl!)
                          : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? Text(
                          firstName.isEmpty
                              ? '?'
                              : firstName[0].toUpperCase(),
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '$greeting${firstName.isEmpty ? '' : ', $firstName'}!',
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your secrets are encrypted end-to-end on this device.',
            style: TextStyle(
              color: cs.onPrimaryContainer.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Native Material 3 SearchBar — gives Android-native styling, ripple,
          // shadow, and accessibility hooks for free.
          SearchBar(
            controller: searchController,
            onChanged: onSearch,
            hintText: 'Search your vault…',
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(cs.surface),
            leading: Icon(Icons.search, color: cs.onSurfaceVariant),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.fg,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

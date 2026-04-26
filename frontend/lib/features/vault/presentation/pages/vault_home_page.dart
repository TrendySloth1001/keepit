import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../auth/presentation/auth_notifier.dart';
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
      ref.read(vaultProvider.notifier).refresh();
      ref.read(storageProvider.notifier).refresh();
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
        context.push('/vault/edit/password', extra: item);
        break;
      case VaultItemType.note:
        context.push('/vault/edit/note', extra: item);
        break;
      case VaultItemType.key:
        context.push('/vault/edit/key', extra: item);
        break;
      case VaultItemType.file:
      case VaultItemType.image:
        context.push('/vault/file', extra: item);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultProvider);
    final notifier = ref.read(vaultProvider.notifier);
    final user = ref.watch(authProvider).user;

    return AutoLockScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(user?.name ?? 'Vault'),
          actions: [
            IconButton(
              tooltip: 'Lock',
              onPressed: () => ref.read(authProvider.notifier).lock(),
              icon: const Icon(Icons.lock_outline),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/vault/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _onAdd,
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: const StorageMeter(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.setSearch,
                  decoration: const InputDecoration(
                    labelText: 'Search by title',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TypeFilter(
                value: state.typeFilter,
                onChanged: notifier.setTypeFilter,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: InlineMessage(
                    message: state.errorMessage!,
                    kind: InlineMessageKind.error,
                  ),
                ),
              Expanded(child: _buildBody(state, notifier)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(VaultListState state, VaultNotifier notifier) {
    if (state.isLoading) {
      return const ShimmerCentered();
    }
    final items = state.visibleItems;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await notifier.refresh();
          await ref.read(storageProvider.notifier).refresh();
        },
        color: AppTheme.white,
        backgroundColor: AppTheme.black,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            EmptyState(
              icon: Icons.lock_outline,
              title: state.search.isEmpty && state.typeFilter == null
                  ? 'Your vault is empty'
                  : 'No matching items',
              message: state.search.isEmpty && state.typeFilter == null
                  ? 'Tap + to add your first encrypted item.'
                  : 'Try a different search or filter.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await notifier.refresh();
        await ref.read(storageProvider.notifier).refresh();
      },
      color: AppTheme.white,
      backgroundColor: AppTheme.black,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        itemCount: items.length + (state.isPaging ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          if (i >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ShimmerBox(width: 120, height: 12, borderRadius: 6),
              ),
            );
          }
          final item = items[i];
          return VaultItemTile(item: item, onTap: () => _onTap(item));
        },
      ),
    );
  }
}

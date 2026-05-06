import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../vault/data/icon_catalog.dart';
import '../../../vault/data/vault_models.dart';
import '../../data/share_models.dart';
import '../share_notifier.dart';

class SharedWithMePage extends ConsumerStatefulWidget {
  const SharedWithMePage({super.key});

  @override
  ConsumerState<SharedWithMePage> createState() => _SharedWithMePageState();
}

class _SharedWithMePageState extends ConsumerState<SharedWithMePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shareProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shareProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: KeepItAppBar(
        title: 'Shared',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(shareProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppTheme.hairline),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppTheme.fg,
                  unselectedLabelColor: AppTheme.muted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Shared with me'),
                    Tab(text: 'Shared by me'),
                  ],
                ),
              ),
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: InlineMessage(
                  message: state.errorMessage!,
                  kind: InlineMessageKind.error,
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _ShareList(
                    items: state.received,
                    isLoading: state.isLoading,
                    incoming: true,
                  ),
                  _ShareList(
                    items: state.sent,
                    isLoading: state.isLoading,
                    incoming: false,
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

class _ShareList extends ConsumerWidget {
  const _ShareList({
    required this.items,
    required this.isLoading,
    required this.incoming,
  });

  final List<SharedItem> items;
  final bool isLoading;
  final bool incoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && items.isEmpty) return const ShimmerCentered();
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.group_outlined,
        title: incoming ? 'Nothing shared with you yet' : 'Nothing shared yet',
        message: incoming
            ? 'When someone shares an item with your email, it will appear here.'
            : 'Open any password, key, file or image and tap the share icon.',
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => ref.read(shareProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.huge,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) =>
            _ShareCard(item: items[i], incoming: incoming),
      ),
    );
  }
}

class _ShareCard extends ConsumerStatefulWidget {
  const _ShareCard({required this.item, required this.incoming});
  final SharedItem item;
  final bool incoming;

  @override
  ConsumerState<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends ConsumerState<_ShareCard> {
  Future<void> _revoke() async {
    await ref.read(shareProvider.notifier).revoke(widget.item);
    if (mounted) {
      showAppSnack(context, 'Removed', kind: AppSnackKind.success);
    }
  }

  String get _typeLabel => switch (widget.item.type) {
        VaultItemType.password => 'Password',
        VaultItemType.note => 'Note',
        VaultItemType.key => 'Key',
        VaultItemType.file => 'File',
        VaultItemType.image => 'Image',
      };

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    final iconKey = IconCatalog.guessFromTitle(i.title).key;
    final partyLabel = widget.incoming
        ? 'From ${i.ownerName.isEmpty ? i.ownerEmail : i.ownerName}'
        : 'To ${i.recipientEmail}';

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => context.push(
          '/vault/shared/view',
          extra: SharedItemViewArgs(item: i, incoming: widget.incoming),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.hairline),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              VaultIcon(iconKey: iconKey, size: 48, iconSize: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(label: _typeLabel),
                        _Chip(
                          label: 'Shared ${formatRelativeTime(i.createdAt)}',
                        ),
                        _Chip(
                          icon: i.canEdit
                              ? Icons.edit_outlined
                              : Icons.visibility_outlined,
                          label: i.canEdit ? 'Can edit' : 'View only',
                        ),
                        if (i.expiresAt != null)
                          _Chip(
                            icon: Icons.timer_outlined,
                            label: i.isExpired
                                ? 'Expired'
                                : 'Revokes in ${formatCountdown(i.expiresAt!)}',
                            tone: i.isExpired
                                ? _ChipTone.danger
                                : _ChipTone.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.muted),
                onSelected: (v) {
                  if (v == 'revoke') _revoke();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'revoke',
                    child: Text(widget.incoming ? 'Remove' : 'Revoke'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ChipTone { neutral, warning, danger }

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, this.tone = _ChipTone.neutral});
  final String label;
  final IconData? icon;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _ChipTone.warning => (
          bg: AppTheme.warning.withValues(alpha: 0.14),
          fg: AppTheme.warning,
        ),
      _ChipTone.danger => (
          bg: AppTheme.error.withValues(alpha: 0.14),
          fg: AppTheme.error,
        ),
      _ => (bg: AppTheme.surfaceAlt, fg: AppTheme.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: colors.fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

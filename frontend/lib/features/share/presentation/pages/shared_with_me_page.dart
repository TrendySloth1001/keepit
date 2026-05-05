import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/network/api_error.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/inline_message.dart';
import '../../../../shared/widgets/keepit_app_bar.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../vault/data/icon_catalog.dart';
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
            : 'Open any password or key and tap the share icon.',
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
  bool _opening = false;
  Map<String, dynamic>? _decrypted;

  Future<void> _open() async {
    if (!widget.incoming) return;
    setState(() => _opening = true);
    try {
      final payload =
          await ref.read(shareProvider.notifier).openReceived(widget.item);
      if (!mounted) return;
      setState(() {
        _decrypted = payload;
        _opening = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _opening = false);
      showAppSnack(
        context,
        'Could not open: ${friendlyApiError(e)}',
        kind: AppSnackKind.error,
      );
    }
  }

  Future<void> _revoke() async {
    await ref.read(shareProvider.notifier).revoke(widget.item);
    if (mounted) {
      showAppSnack(context, 'Removed', kind: AppSnackKind.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    final iconKey = IconCatalog.guessFromTitle(i.title).key;

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: widget.incoming ? _open : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppTheme.hairline),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  VaultIcon(iconKey: iconKey, size: 44),
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
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.incoming
                              ? 'Shared by ${i.ownerName.isEmpty ? i.ownerEmail : i.ownerName}'
                              : 'Shared with ${i.recipientEmail}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Shared ${formatRelativeTime(i.createdAt)}',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
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
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _MiniChip(
                    icon: i.canEdit
                        ? Icons.edit_outlined
                        : Icons.visibility_outlined,
                    label: i.canEdit ? 'Can Edit' : 'View Only',
                  ),
                  const SizedBox(width: 6),
                  _MiniChip(
                    icon: Icons.lock_outline,
                    label: 'End-to-end encrypted',
                  ),
                ],
              ),
              if (_opening) ...[
                const SizedBox(height: AppSpacing.md),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (_decrypted != null) ...[
                const SizedBox(height: AppSpacing.md),
                _DecryptedPreview(payload: _decrypted!, type: i.type),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.fg,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecryptedPreview extends StatelessWidget {
  const _DecryptedPreview({required this.payload, required this.type});
  final Map<String, dynamic> payload;
  final dynamic type;

  @override
  Widget build(BuildContext context) {
    final entries = payload.entries
        .where((e) => e.value != null && '${e.value}'.isNotEmpty)
        .toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.heroGreen,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      '${e.value}',
                      style: const TextStyle(
                        color: AppTheme.fg,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

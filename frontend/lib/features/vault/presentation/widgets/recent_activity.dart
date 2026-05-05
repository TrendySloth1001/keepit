import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/vault_models.dart';
import '../vault_notifier.dart';

/// A simple feed of recent vault activity, derived from each item's
/// `updatedAt`/`createdAt` timestamps. We don't keep a server-side audit log
/// yet, so we infer "Added" vs "Updated" from whether create == update.
class RecentActivity extends ConsumerWidget {
  const RecentActivity({super.key, this.limit = 5});
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(vaultProvider).items;
    final sorted = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final feed = sorted.take(limit).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  color: AppTheme.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (items.length > limit)
                Text(
                  '${items.length} total',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (feed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'Nothing yet — add your first item to see it here.',
                style: TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            )
          else
            for (var i = 0; i < feed.length; i++) ...[
              _ActivityRow(item: feed[i]),
              if (i < feed.length - 1)
                const Divider(color: AppTheme.hairline, height: 16),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final VaultItem item;

  @override
  Widget build(BuildContext context) {
    final added =
        item.createdAt.isAtSameMomentAs(item.updatedAt) ||
            item.updatedAt.difference(item.createdAt).inSeconds < 5;
    final IconData icon;
    final Color tint;
    final String verb;
    if (added) {
      icon = Icons.add;
      tint = AppTheme.ink;
      verb = 'Added';
    } else {
      icon = Icons.edit_outlined;
      tint = AppTheme.muted;
      verb = 'Updated';
    }

    return Row(
      children: [
        IconBadge(
          icon: icon,
          tint: AppTheme.white,
          background: tint,
          size: 36,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$verb ${item.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatRelativeTime(item.updatedAt)} · ${_typeLabel(item)}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _typeLabel(VaultItem i) => switch (i.type) {
        VaultItemType.password => 'Password',
        VaultItemType.note => 'Note',
        VaultItemType.key => 'Key',
        VaultItemType.file => 'File',
        VaultItemType.image => 'Image',
      };
}

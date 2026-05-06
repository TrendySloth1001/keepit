import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../data/vault_models.dart';
import '../storage_notifier.dart';

class StorageMeter extends ConsumerStatefulWidget {
  const StorageMeter({super.key, this.onUpgrade});

  final VoidCallback? onUpgrade;

  @override
  ConsumerState<StorageMeter> createState() => _StorageMeterState();
}

class _StorageMeterState extends ConsumerState<StorageMeter> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storageProvider);
    final stats = state.stats;
    final used = stats?.bytesUsed ?? 0;
    final quota = stats?.quotaBytes ?? 524288000;
    final fraction = (stats?.fraction ?? 0).clamp(0.0, 1.0);
    final near = fraction >= 0.8 && fraction < 0.95;
    final full = fraction >= 0.95;
    final color = full
        ? AppTheme.error
        : near
        ? AppTheme.warning
        : AppTheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppTheme.hairline),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatBytes(used)} of ${formatBytes(quota)} used',
                            style: const TextStyle(
                              color: AppTheme.fg,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(100 - fraction * 100).round()}% storage remaining',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(fraction * 100).round()}%',
                      style: const TextStyle(
                        color: AppTheme.fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.muted,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: AppTheme.surfaceAlt,
                    color: color,
                    minHeight: 8,
                  ),
                ),
                if (_isExpanded) ...[
                  if (stats != null && stats.breakdown.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    for (final b in stats.breakdown) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _colorFor(b.type),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _labelFor(b.type),
                                style: const TextStyle(
                                  color: AppTheme.fg,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              formatBytes(b.bytes),
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  if (full || near) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      full
                          ? 'Storage is full — delete files to make room'
                          : 'Getting close to your storage limit',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ],
                  if (widget.onUpgrade != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppTheme.hairline, height: 1),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            size: 20,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upgrade to Premium',
                                style: TextStyle(
                                  color: AppTheme.fg,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '2 GB and unlimited items',
                                style: TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onUpgrade,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryDark,
                            backgroundColor: AppTheme.primarySoft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Upgrade',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (widget.onUpgrade != null && !_isExpanded)
          Positioned(
            top: -12,
            right: -8,
            child: Material(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                onTap: widget.onUpgrade,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 14,
                        color: AppTheme.primaryDark,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Upgrade to 2GB',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _colorFor(VaultItemType t) => switch (t) {
    VaultItemType.password => AppTheme.primary,
    VaultItemType.note => const Color(0xFFE08A1A),
    VaultItemType.key => const Color(0xFF1E78D6),
    VaultItemType.file => AppTheme.ink,
    VaultItemType.image => const Color(0xFFE4405F),
  };

  String _labelFor(VaultItemType t) => switch (t) {
    VaultItemType.password => 'Passwords',
    VaultItemType.note => 'Notes',
    VaultItemType.key => 'Keys',
    VaultItemType.file => 'Documents',
    VaultItemType.image => 'Images',
  };
}

/// Promo card mirroring the Glassdoor-style "Upgrade to Premium" tile.
class UpgradeBanner extends StatelessWidget {
  const UpgradeBanner({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppTheme.ink,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '50 GB storage and unlimited items',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.ink,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

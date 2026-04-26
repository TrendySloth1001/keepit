import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../storage_notifier.dart';

class StorageMeter extends ConsumerWidget {
  const StorageMeter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storageProvider);
    final stats = state.stats;
    final used = stats?.bytesUsed ?? 0;
    final quota = stats?.quotaBytes ?? 524288000;
    final fraction = stats?.fraction ?? 0;
    final near = fraction >= 0.8 && fraction < 0.95;
    final full = fraction >= 0.95;
    final color = full
        ? AppTheme.error
        : near
        ? AppTheme.warning
        : AppTheme.white;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.black,
        border: Border.all(color: AppTheme.white),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Storage',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: AppType.caption,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${formatBytes(used)} / ${formatBytes(quota)}',
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: AppType.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.brSm,
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.white),
                      borderRadius: AppRadius.brSm,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
          if (full || near) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              full
                  ? 'Storage is full. Delete files to make room.'
                  : 'Approaching your storage limit.',
              style: TextStyle(color: color, fontSize: AppType.micro),
            ),
          ],
        ],
      ),
    );
  }
}

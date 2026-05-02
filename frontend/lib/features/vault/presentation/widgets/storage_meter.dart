import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/sketch.dart';
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
    final fraction = (stats?.fraction ?? 0).clamp(0, 1).toDouble();
    final near = fraction >= 0.8 && fraction < 0.95;
    final full = fraction >= 0.95;
    final color = full
        ? AppTheme.error
        : near
            ? AppTheme.warning
            : AppTheme.primary;

    return SketchBox(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: 16,
      fill: AppTheme.surface,
      seed: 42,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'storage',
                style: GoogleFonts.caveat(
                  color: AppTheme.fg,
                  fontSize: 22,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${formatBytes(used)} / ${formatBytes(quota)}',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: AppType.body,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 22,
            width: double.infinity,
            child: CustomPaint(
              size: Size.infinite,
              painter: _MeterPainter(fraction: fraction, fill: color),
            ),
          ),
          if (full || near) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              full
                  ? 'storage is full — delete files to make room'
                  : 'getting close to your storage limit',
              style: TextStyle(color: color, fontSize: AppType.body),
            ),
          ],
        ],
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({required this.fraction, required this.fill});
  final double fraction;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Offset.zero & size;
    // Background track — full width, faint fill so the empty portion reads.
    final outline = SketchPaint.roughRRect(rect.deflate(1.5), 6,
        seed: Object.hash(99, size.width.round()), jitter: 1.0);
    canvas.drawPath(
      outline,
      Paint()..color = AppTheme.plaster..style = PaintingStyle.fill,
    );
    // Filled portion. Clamp to a minimum visible width when fraction > 0.
    if (fraction > 0) {
      final minW = 8.0;
      final w = max(minW, size.width * fraction);
      final filled = Rect.fromLTWH(0, 0, w, size.height);
      final fillPath = SketchPaint.roughRRect(filled.deflate(2), 5,
          seed: Object.hash(100, size.width.round()), jitter: 1.4);
      canvas.drawPath(fillPath, Paint()..color = fill..style = PaintingStyle.fill);
      SketchPaint.hatch(canvas, fillPath,
          color: AppTheme.onPrimary.withValues(alpha: 0.30),
          spacing: 5,
          seed: 101);
    }
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppTheme.fg
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outline, pen);
    // Second pen pass for the hand-drawn double-stroke feel.
    canvas.drawPath(
      SketchPaint.roughRRect(rect.deflate(1.5).shift(const Offset(0.4, 0.3)), 6,
          seed: Object.hash(99, size.width.round()) + 1, jitter: 0.8),
      pen..strokeWidth = 0.9,
    );
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.fraction != fraction || old.fill != fill;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/sketch.dart';
import '../../app/theme/tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 96,
            width: 96,
            child: CustomPaint(
              painter: _StampPainter(seed: title.hashCode),
              child: Center(
                child: Icon(icon, size: 40, color: AppTheme.fg),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.caveat(
              color: AppTheme.fg,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: AppType.body,
              height: 1.4,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  _StampPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final border = const RoughCircleBorder(color: AppTheme.fg, strokeWidth: 1.6);
    final path = border.getOuterPath(rect);
    SketchPaint.hatch(canvas, path,
        color: AppTheme.primary.withValues(alpha: 0.35),
        spacing: 6,
        seed: seed);
    border.paint(canvas, rect);
  }

  @override
  bool shouldRepaint(covariant _StampPainter old) => old.seed != seed;
}

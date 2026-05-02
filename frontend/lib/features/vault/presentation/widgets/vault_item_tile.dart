import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/sketch.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../data/vault_models.dart';

class VaultItemTile extends StatelessWidget {
  const VaultItemTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  final VaultItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  IconData get _icon => switch (item.type) {
        VaultItemType.password => Icons.password,
        VaultItemType.note => Icons.notes,
        VaultItemType.key => Icons.key,
        VaultItemType.file => Icons.attach_file,
        VaultItemType.image => Icons.image_outlined,
      };

  String get _typeLabel => switch (item.type) {
        VaultItemType.password => 'Password',
        VaultItemType.note => 'Note',
        VaultItemType.key => 'Key',
        VaultItemType.file => 'File',
        VaultItemType.image => 'Image',
      };

  /// Tiny per-tile rotation so each card looks pasted in by hand. Seeded
  /// off the item id so the same item keeps the same tilt across rebuilds.
  double get _tilt {
    final h = item.id.hashCode;
    return ((h % 100) / 100 - 0.5) * 0.018; // ~±0.5°
  }

  @override
  Widget build(BuildContext context) {
    final size = item.fileSize;
    final pending = item.uploadStatus == 'pending';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Transform.rotate(
        angle: _tilt,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadius.brLg,
          child: SketchBox(
            padding: const EdgeInsets.all(AppSpacing.md),
            radius: 16,
            fill: AppTheme.surface,
            seed: item.id.hashCode,
            child: Row(
              children: [
                _SketchAvatar(icon: _icon, seed: item.id.hashCode),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.caveat(
                          color: AppTheme.fg,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          _typeLabel,
                          if (size != null) formatBytes(size),
                          formatRelativeTime(item.updatedAt),
                          if (pending) 'pending',
                        ].join(' · '),
                        style: TextStyle(
                          color: pending ? AppTheme.warning : AppTheme.muted,
                          fontSize: AppType.micro,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SketchAvatar extends StatelessWidget {
  const _SketchAvatar({required this.icon, required this.seed});
  final IconData icon;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.avatarMd,
      height: AppLayout.avatarMd,
      child: CustomPaint(
        painter: _AvatarPainter(seed: seed),
        child: Center(
          child: Icon(icon, color: AppTheme.onPrimary, size: AppIconSize.md),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final border = const RoughCircleBorder(color: AppTheme.fg, strokeWidth: 1.4);
    final path = border.getOuterPath(rect);
    canvas.drawPath(path, Paint()..color = AppTheme.primary..style = PaintingStyle.fill);
    SketchPaint.hatch(canvas, path,
        color: AppTheme.onPrimary.withValues(alpha: 0.18),
        spacing: 4,
        seed: seed);
    border.paint(canvas, rect);
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.seed != seed;
}

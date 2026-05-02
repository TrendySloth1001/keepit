import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/sketch.dart';
import '../../../../app/theme/tokens.dart';
import '../../data/vault_models.dart';

Future<VaultItemType?> showTypePicker(BuildContext context) {
  return showModalBottomSheet<VaultItemType>(
    context: context,
    backgroundColor: AppTheme.bg,
    shape: const RoughRectBorder(radius: 22, jitter: 2.0, seed: 73),
    builder: (_) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New item',
              style: GoogleFonts.caveat(
                color: AppTheme.fg,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final (i, entry) in const [
              (VaultItemType.password, 'Password', Icons.password,
                  'Username, password, URL, notes'),
              (VaultItemType.note, 'Secure note', Icons.notes,
                  'Encrypted long-form note'),
              (VaultItemType.key, 'API key / token', Icons.key,
                  'Tokens, recovery codes, secrets'),
              (VaultItemType.image, 'Image', Icons.image_outlined,
                  'Encrypt and store an image'),
              (VaultItemType.file, 'File', Icons.attach_file,
                  'Encrypt and store any file'),
            ].indexed)
              _TypeRow(
                type: entry.$1,
                title: entry.$2,
                icon: entry.$3,
                subtitle: entry.$4,
                index: i,
              ),
          ],
        ),
      ),
    ),
  );
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.index,
  });

  final VaultItemType type;
  final String title;
  final IconData icon;
  final String subtitle;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tilt = (index.isEven ? 1 : -1) * 0.006;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Transform.rotate(
        angle: tilt,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(type),
          borderRadius: AppRadius.brMd,
          child: SketchBox(
            padding: const EdgeInsets.all(AppSpacing.md),
            radius: 14,
            fill: AppTheme.surface,
            seed: title.hashCode,
            child: Row(
              children: [
                _SketchIconCircle(icon: icon, seed: title.hashCode),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.patrickHand(
                          color: AppTheme.fg,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.muted,
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

class _SketchIconCircle extends StatelessWidget {
  const _SketchIconCircle({required this.icon, required this.seed});
  final IconData icon;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.avatarSm,
      height: AppLayout.avatarSm,
      child: CustomPaint(
        size: Size.infinite,
        painter: _CirclePainter(seed: seed),
        child: Center(
          child: Icon(icon, color: AppTheme.fg, size: AppIconSize.sm),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final border = RoughCircleBorder(
        color: AppTheme.fg, strokeWidth: 1.4, seed: seed);
    border.paint(canvas, rect);
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.seed != seed;
}

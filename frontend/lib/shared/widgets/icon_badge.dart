import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Circular tinted badge holding a single icon. Used in settings tiles,
/// activity rows, and help cards.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.tint,
    this.background,
    this.iconSize,
  });

  final IconData icon;
  final double size;
  final Color? tint;
  final Color? background;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final fg = tint ?? AppTheme.fg;
    final bg = background ?? AppTheme.surfaceAlt;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: iconSize ?? size * 0.5),
    );
  }
}

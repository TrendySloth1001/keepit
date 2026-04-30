import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KeepItLogo extends StatelessWidget {
  final double size;
  final Color? foregroundColor;
  final bool showBackground;

  const KeepItLogo({
    super.key,
    this.size = 40,
    this.foregroundColor,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: 'KeepIt logo',
      child: Container(
        width: size,
        height: size,
        decoration: showBackground
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              )
            : null,
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          width: size * 0.72,
          height: size * 0.72,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
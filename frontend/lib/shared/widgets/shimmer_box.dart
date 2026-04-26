import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 10,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (2.0 * t), -0.3),
              end: Alignment(1.0 + (2.0 * t), 0.3),
              colors: const [
                Color(0xFF191919),
                Color(0xFF2A2A2A),
                Color(0xFF191919),
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
            border: Border.all(color: AppTheme.white.withValues(alpha: 0.15)),
          ),
        );
      },
    );
  }
}

class ShimmerCentered extends StatelessWidget {
  const ShimmerCentered({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerBox(width: 52, height: 52, borderRadius: 26),
          SizedBox(height: 12),
          ShimmerBox(width: 160, height: 12),
        ],
      ),
    );
  }
}

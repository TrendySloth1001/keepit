import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Hand-drawn / sketchbook primitives.
///
/// All paths are jittered deterministically (seeded by the size of the
/// thing being drawn) so the lines stay still between rebuilds — rebuilds
/// without a stable seed would shimmer like a strobe-light flipbook.
class SketchPaint {
  SketchPaint._();

  /// Generate a slightly wobbly rounded-rectangle path. Walks each edge in
  /// short segments and offsets every joint perpendicular to the edge by a
  /// small random amount.
  static Path roughRRect(
    Rect rect,
    double radius, {
    required int seed,
    double jitter = 1.6,
    double segment = 14,
  }) {
    final r = radius.clamp(0.0, rect.shortestSide / 2);
    final rng = Random(seed);
    double j() => (rng.nextDouble() - 0.5) * 2 * jitter;

    final path = Path();
    void lineSegment(double x1, double y1, double x2, double y2, double nx, double ny) {
      final dx = x2 - x1;
      final dy = y2 - y1;
      final len = sqrt(dx * dx + dy * dy);
      if (len < 0.001) return;
      final steps = max(1, (len / segment).ceil());
      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        final px = x1 + dx * t + nx * j();
        final py = y1 + dy * t + ny * j();
        path.lineTo(px, py);
      }
    }

    // Move to start of top edge after the top-left corner.
    path.moveTo(rect.left + r, rect.top + j());
    // Top edge — normal points up.
    lineSegment(rect.left + r, rect.top, rect.right - r, rect.top, 0, -1);
    // Top-right arc, manually approximated with jitter.
    _arc(path, Offset(rect.right - r, rect.top + r), r, -pi / 2, 0, rng, jitter);
    // Right edge — normal points right.
    lineSegment(rect.right, rect.top + r, rect.right, rect.bottom - r, 1, 0);
    _arc(path, Offset(rect.right - r, rect.bottom - r), r, 0, pi / 2, rng, jitter);
    // Bottom edge.
    lineSegment(rect.right - r, rect.bottom, rect.left + r, rect.bottom, 0, 1);
    _arc(path, Offset(rect.left + r, rect.bottom - r), r, pi / 2, pi, rng, jitter);
    // Left edge.
    lineSegment(rect.left, rect.bottom - r, rect.left, rect.top + r, -1, 0);
    _arc(path, Offset(rect.left + r, rect.top + r), r, pi, 3 * pi / 2, rng, jitter);
    path.close();
    return path;
  }

  static void _arc(
    Path p,
    Offset center,
    double r,
    double start,
    double end,
    Random rng,
    double jitter,
  ) {
    const steps = 8;
    final span = end - start;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final ang = start + span * t;
      final dr = r + (rng.nextDouble() - 0.5) * 2 * jitter;
      p.lineTo(center.dx + cos(ang) * dr, center.dy + sin(ang) * dr);
    }
  }

  /// Diagonal cross-hatch / pencil-shading pattern, clipped to [path].
  static void hatch(
    Canvas canvas,
    Path path, {
    Color color = const Color(0x55EAAAB2),
    double spacing = 6,
    double angle = -pi / 4,
    double strokeWidth = 1,
    int seed = 0,
  }) {
    final bounds = path.getBounds();
    canvas.save();
    canvas.clipPath(path);
    final rng = Random(seed);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    // Long diagonal across the bounds, then translate perpendicular by `spacing`.
    final diag = bounds.longestSide * 1.6;
    final cx = bounds.center.dx;
    final cy = bounds.center.dy;
    final dx = cos(angle);
    final dy = sin(angle);
    final nx = -dy;
    final ny = dx;
    final lines = (bounds.longestSide / spacing).ceil();
    for (var i = -lines; i <= lines; i++) {
      final off = i * spacing + (rng.nextDouble() - 0.5) * 0.8;
      final ox = cx + nx * off;
      final oy = cy + ny * off;
      final p1 = Offset(ox - dx * diag / 2, oy - dy * diag / 2);
      final p2 = Offset(ox + dx * diag / 2, oy + dy * diag / 2);
      canvas.drawLine(p1, p2, paint);
    }
    canvas.restore();
  }
}

/// An `OutlinedBorder` that draws a hand-drawn double-stroke outline.
/// Works anywhere Flutter accepts a [ShapeBorder] *or* an [OutlinedBorder]
/// (Card, BottomSheet, ElevatedButton, FAB, dialogs, popups…).
class RoughRectBorder extends OutlinedBorder {
  const RoughRectBorder({
    this.radius = 14,
    this.color = AppTheme.fg,
    this.strokeWidth = 1.4,
    this.jitter = 1.6,
    this.seed = 17,
    this.doubleStroke = true,
  });

  final double radius;
  final Color color;
  final double strokeWidth;
  final double jitter;
  final int seed;

  /// Draws the outline twice with small offsets to mimic two ink passes
  /// of a hand-held pen.
  final bool doubleStroke;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(strokeWidth + jitter);

  @override
  RoughRectBorder copyWith({
    BorderSide? side,
    double? radius,
    Color? color,
    double? strokeWidth,
    double? jitter,
    int? seed,
    bool? doubleStroke,
  }) =>
      RoughRectBorder(
        radius: radius ?? this.radius,
        color: color ?? side?.color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        jitter: jitter ?? this.jitter,
        seed: seed ?? this.seed,
        doubleStroke: doubleStroke ?? this.doubleStroke,
      );

  @override
  RoughRectBorder scale(double t) => RoughRectBorder(
        radius: radius * t,
        color: color,
        strokeWidth: strokeWidth * t,
        jitter: jitter * t,
        seed: seed,
        doubleStroke: doubleStroke,
      );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(strokeWidth), Radius.circular(radius)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      SketchPaint.roughRRect(rect, radius, seed: _seedFor(rect), jitter: jitter);

  int _seedFor(Rect rect) =>
      Object.hash(seed, rect.width.round(), rect.height.round());

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final s = _seedFor(rect);
    canvas.drawPath(SketchPaint.roughRRect(rect, radius, seed: s, jitter: jitter), paint);
    if (doubleStroke) {
      canvas.drawPath(
        SketchPaint.roughRRect(rect.shift(const Offset(0.6, 0.4)), radius,
            seed: s + 1, jitter: jitter * 0.8),
        paint..strokeWidth = strokeWidth * 0.7,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RoughRectBorder &&
      other.radius == radius &&
      other.color == color &&
      other.strokeWidth == strokeWidth &&
      other.jitter == jitter &&
      other.seed == seed &&
      other.doubleStroke == doubleStroke;

  @override
  int get hashCode => Object.hash(radius, color, strokeWidth, jitter, seed, doubleStroke);
}

/// A circular sketch border (avatars, FAB, icon buttons).
class RoughCircleBorder extends OutlinedBorder {
  const RoughCircleBorder({
    this.color = AppTheme.fg,
    this.strokeWidth = 1.4,
    this.jitter = 2.4,
    this.seed = 9,
  });

  final Color color;
  final double strokeWidth;
  final double jitter;
  final int seed;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(strokeWidth + jitter);

  @override
  RoughCircleBorder copyWith({
    BorderSide? side,
    Color? color,
    double? strokeWidth,
    double? jitter,
    int? seed,
  }) =>
      RoughCircleBorder(
        color: color ?? side?.color ?? this.color,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        jitter: jitter ?? this.jitter,
        seed: seed ?? this.seed,
      );

  @override
  RoughCircleBorder scale(double t) =>
      RoughCircleBorder(color: color, strokeWidth: strokeWidth * t, jitter: jitter * t, seed: seed);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addOval(rect.deflate(strokeWidth));

  Path _circlePath(Rect rect, int s, {double jitterScale = 1.0}) {
    final path = Path();
    final rng = Random(s);
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    // Fewer steps + larger jitter → more visibly hand-drawn.
    const steps = 22;
    // Random starting angle so the "seam" doesn't always sit at 3 o'clock.
    final startAng = rng.nextDouble() * 2 * pi;
    final j = jitter * jitterScale;
    // Slight overshoot so the line crosses itself like a real pen sketch.
    final overshoot = (rng.nextDouble() * 0.18 + 0.08) * 2 * pi;
    final total = 2 * pi + overshoot;
    for (var i = 0; i <= steps; i++) {
      final t = startAng + total * (i / steps);
      // Per-vertex radial wobble + a slow low-freq wobble for organic shape.
      final lowFreq = sin(t * 2 + rng.nextDouble()) * j * 0.4;
      final dr = (rng.nextDouble() - 0.5) * 2 * j + lowFreq;
      final x = cx + cos(t) * (rx + dr);
      final y = cy + sin(t) * (ry + dr);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _circlePath(rect, Object.hash(seed, rect.width.round(), rect.height.round()));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final s = Object.hash(seed, rect.width.round(), rect.height.round());
    canvas.drawPath(_circlePath(rect, s), paint);
    canvas.drawPath(
      _circlePath(rect.shift(const Offset(0.7, 0.5)), s + 1, jitterScale: 0.8),
      paint..strokeWidth = strokeWidth * 0.7,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RoughCircleBorder &&
      other.color == color &&
      other.strokeWidth == strokeWidth &&
      other.jitter == jitter &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(color, strokeWidth, jitter, seed);
}

/// Hand-drawn input border — wobbly outline with optional bottom-only mode.
class SketchInputBorder extends InputBorder {
  const SketchInputBorder({
    this.radius = 14,
    this.color = AppTheme.fg,
    this.strokeWidth = 1.3,
    this.jitter = 1.4,
    this.seed = 31,
  }) : super(borderSide: const BorderSide(color: AppTheme.fg, width: 1.3));

  final double radius;
  final Color color;
  final double strokeWidth;
  final double jitter;
  final int seed;

  @override
  bool get isOutline => true;

  @override
  InputBorder copyWith({BorderSide? borderSide}) => this;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(strokeWidth + jitter);

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(strokeWidth), Radius.circular(radius)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      SketchPaint.roughRRect(rect, radius,
          seed: Object.hash(seed, rect.width.round()), jitter: jitter);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final s = Object.hash(seed, rect.width.round(), rect.height.round());
    canvas.drawPath(SketchPaint.roughRRect(rect, radius, seed: s, jitter: jitter), paint);
    canvas.drawPath(
      SketchPaint.roughRRect(rect.shift(const Offset(0.5, 0.3)), radius,
          seed: s + 1, jitter: jitter * 0.7),
      paint..strokeWidth = strokeWidth * 0.65,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SketchInputBorder &&
      other.radius == radius &&
      other.color == color &&
      other.strokeWidth == strokeWidth &&
      other.jitter == jitter;

  @override
  int get hashCode => Object.hash(radius, color, strokeWidth, jitter);
}

/// A surface with a hand-drawn outline, optional diagonal hatch fill, and a
/// faint "doodle margin" — drop this in place of any rectangular Container.
class SketchBox extends StatelessWidget {
  const SketchBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.fill,
    this.borderColor = AppTheme.fg,
    this.hatchColor,
    this.hatchSpacing = 7,
    this.tilt = 0,
    this.seed = 11,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? fill;
  final Color borderColor;

  /// If non-null, applies a diagonal pencil-shade fill behind the child.
  final Color? hatchColor;
  final double hatchSpacing;

  /// Small fixed rotation, in radians, for that "torn-out-of-a-notebook"
  /// look. Use ~0.005–0.02 for subtle tilt; 0 keeps it square.
  final double tilt;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final box = CustomPaint(
      painter: _SketchBoxPainter(
        radius: radius,
        fill: fill,
        border: borderColor,
        hatch: hatchColor,
        hatchSpacing: hatchSpacing,
        seed: seed,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (tilt == 0) return box;
    return Transform.rotate(angle: tilt, child: box);
  }
}

class _SketchBoxPainter extends CustomPainter {
  _SketchBoxPainter({
    required this.radius,
    required this.fill,
    required this.border,
    required this.hatch,
    required this.hatchSpacing,
    required this.seed,
  });

  final double radius;
  final Color? fill;
  final Color border;
  final Color? hatch;
  final double hatchSpacing;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stableSeed = Object.hash(seed, size.width.round(), size.height.round());
    final outer = SketchPaint.roughRRect(rect.deflate(2), radius, seed: stableSeed);
    if (fill != null) {
      canvas.drawPath(outer, Paint()..color = fill!..style = PaintingStyle.fill);
    }
    if (hatch != null) {
      SketchPaint.hatch(canvas, outer,
          color: hatch!, spacing: hatchSpacing, seed: stableSeed);
    }
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..color = border
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(outer, pen);
    canvas.drawPath(
      SketchPaint.roughRRect(rect.deflate(2).shift(const Offset(0.6, 0.4)),
          radius,
          seed: stableSeed + 1,
          jitter: 1.2),
      pen..strokeWidth = 0.9,
    );
  }

  @override
  bool shouldRepaint(_SketchBoxPainter old) =>
      old.fill != fill ||
      old.border != border ||
      old.hatch != hatch ||
      old.radius != radius ||
      old.hatchSpacing != hatchSpacing ||
      old.seed != seed;
}

/// Sketch-styled CTA: pink-hatched fill, hand-drawn outline, optional
/// little hand-drawn underline behind the label.
class SketchButton extends StatelessWidget {
  const SketchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.busy = false,
    this.tilt = 0,
    this.fill = AppTheme.primary,
    this.foreground = AppTheme.onPrimary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final bool busy;
  final double tilt;
  final Color fill;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final content = busy
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          );
    return Transform.rotate(
      angle: tilt,
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SketchBox(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          radius: 14,
          fill: fill,
          hatchColor: foreground.withValues(alpha: 0.18),
          hatchSpacing: 6,
          seed: label.hashCode,
          child: Center(child: content),
        ),
      ),
    );
  }
}

/// Stamps a faint diagonal-hatch background onto any child — used as the
/// scaffold backdrop so the whole app reads as "graph-paper rough work".
class SketchPaper extends StatelessWidget {
  const SketchPaper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _PaperPainter(), child: child);
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppTheme.bg);
    // Notebook ruling — very faint horizontal pencil lines.
    final ruling = Paint()
      ..color = AppTheme.porpoise.withValues(alpha: 0.35)
      ..strokeWidth = 0.6;
    const lineGap = 26.0;
    final rng = Random(7);
    for (var y = 8.0; y < size.height; y += lineGap) {
      final wobble = (rng.nextDouble() - 0.5) * 1.4;
      canvas.drawLine(Offset(0, y + wobble), Offset(size.width, y - wobble), ruling);
    }
    // A single pink "margin" line on the left like a school notebook.
    final margin = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    final p = Path()
      ..moveTo(36, 0)
      ..lineTo(36, size.height);
    final dashed = ui.Path();
    const dash = 6.0;
    const gap = 4.0;
    var d = 0.0;
    final m = p.computeMetrics().first;
    while (d < m.length) {
      dashed.addPath(m.extractPath(d, (d + dash).clamp(0, m.length)), Offset.zero);
      d += dash + gap;
    }
    canvas.drawPath(dashed, margin..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

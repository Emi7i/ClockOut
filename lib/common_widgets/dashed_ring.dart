import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// An ellipse (or circle) drawn as real vector dashes that keep sliding
/// along it.
///
/// [turns] is the progress around the ring as a fraction of a full turn (any
/// value; it wraps). Dashes and gaps are equal and evenly spaced along the
/// arc length, so changing [turns] looks like the dashes travelling.
class DashedRing extends StatelessWidget {
  final Offset center;
  final double radiusX;
  final double radiusY;
  final double strokeWidth;
  final double dashLength;
  final Color color;
  final double turns;

  const DashedRing({
    super.key,
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.strokeWidth,
    required this.dashLength,
    required this.color,
    this.turns = 0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRingPainter(
        center: center,
        radiusX: radiusX,
        radiusY: radiusY,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        color: color,
        turns: turns,
      ),
      size: Size.infinite,
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Offset center;
  final double radiusX;
  final double radiusY;
  final double strokeWidth;
  final double dashLength;
  final Color color;
  final double turns;

  _DashedRingPainter({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.strokeWidth,
    required this.dashLength,
    required this.color,
    required this.turns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Path()
      ..addOval(Rect.fromCenter(
          center: center, width: radiusX * 2, height: radiusY * 2));
    final metric = ring.computeMetrics().first;
    final length = metric.length;

    // Equal dashes and gaps, adjusted so they close the ring exactly.
    final count = (length / (2 * dashLength)).round();
    if (count < 1) return;
    final step = length / count; // one dash + one gap
    final dash = step / 2;
    // Sliding by one step looks identical, so only the remainder matters.
    final shift = (turns * length) % step;

    final path = Path();
    for (var i = -1; i < count; i++) {
      final start = i * step + shift;
      final from = math.max(0.0, start);
      final to = math.min(length, start + dash);
      if (to > from) path.addPath(metric.extractPath(from, to), Offset.zero);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) =>
      old.center != center ||
      old.radiusX != radiusX ||
      old.radiusY != radiusY ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.color != color ||
      old.turns != turns;
}

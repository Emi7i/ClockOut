import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:material_ui/material_ui.dart';

/// Heading (radians, screen coordinates: 0 = right, positive = clockwise,
/// i.e. towards the bottom) of [path] at [fraction] (0..1) of its length.
double pathHeadingAt(Path path, double fraction) {
  final metric = path.computeMetrics().first;
  final t = metric.getTangentForOffset(
      metric.length * fraction.clamp(0.0, 1.0))!;
  return math.atan2(t.vector.dy, t.vector.dx);
}

/// A body riding an orbit path: a solid line behind it (what is there) and a
/// dashed line ahead (what is missing).
///
/// [progress] runs from 0 (start of [path]) to 1 (end), as a fraction of the
/// path's length. The path is real vector data, in this widget's own
/// coordinates (scale it before passing it in).
///
/// [bodyBuilder] draws the body. Its top-left corner (0, 0) sits exactly on
/// the path point, so it should shift itself to put the body's centre (or a
/// comet's head) there. [heading] is the path's direction at that point.
class OrbitTrack extends StatefulWidget {
  final Path path;
  final double progress;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final Widget Function(BuildContext context, double heading) bodyBuilder;

  const OrbitTrack({
    super.key,
    required this.path,
    required this.progress,
    required this.bodyBuilder,
    this.color = Colors.white,
    this.strokeWidth = 3,
    this.dashLength = 3,
    this.gapLength = 4,
  });

  @override
  State<OrbitTrack> createState() => _OrbitTrackState();
}

class _OrbitTrackState extends State<OrbitTrack> {
  late PathMetric _metric = widget.path.computeMetrics().first;

  @override
  void didUpdateWidget(OrbitTrack old) {
    super.didUpdateWidget(old);
    if (!identical(old.path, widget.path)) {
      _metric = widget.path.computeMetrics().first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress.clamp(0.0, 1.0);
    final tangent = _metric.getTangentForOffset(_metric.length * p)!;
    final heading = math.atan2(tangent.vector.dy, tangent.vector.dx);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: _TrackPainter(
            metric: _metric,
            progress: p,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
            dashLength: widget.dashLength,
            gapLength: widget.gapLength,
          ),
        ),
        Positioned(
          left: tangent.position.dx,
          top: tangent.position.dy,
          child: widget.bodyBuilder(context, heading),
        ),
      ],
    );
  }
}

class _TrackPainter extends CustomPainter {
  final PathMetric metric;
  final double progress;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _TrackPainter({
    required this.metric,
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final length = metric.length;
    final split = length * progress;

    // Behind the body: solid.
    if (split > 0) canvas.drawPath(metric.extractPath(0, split), paint);

    // Ahead of the body: dashes, starting right at the body.
    final dashes = Path();
    for (var d = split; d < length; d += dashLength + gapLength) {
      dashes.addPath(
        metric.extractPath(d, math.min(d + dashLength, length)),
        Offset.zero,
      );
    }
    canvas.drawPath(dashes, paint);
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      !identical(old.metric, metric) ||
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

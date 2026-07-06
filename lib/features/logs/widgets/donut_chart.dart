import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

/// ─────────────────────────────────────────────────────────────
///  DONUT CHART
///  Dashed circular progress ring showing weekly/monthly hours.
///  Swap [size] or [strokeWidth] to resize.
/// ─────────────────────────────────────────────────────────────
class DonutChart extends StatelessWidget {
  final double hoursWorked;
  final double hoursTarget;
  final double progress; // 0.0 – 1.0
  final String periodLabel;

  /// ← change size here
  final double size;

  const DonutChart({
    super.key,
    required this.hoursWorked,
    required this.hoursTarget,
    required this.progress,
    this.periodLabel = 'hours this week',
    this.size = AppDimensions.donutSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Hours label ─────────────────────────────
              Text(
                '${hoursWorked.toStringAsFixed(0)} / ${hoursTarget.toStringAsFixed(0)}',
                style: AppTextStyles.donutPrimary,
              ),
              Text(periodLabel, style: AppTextStyles.donutSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double progress;

  const _DonutPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - AppDimensions.donutStrokeWidth / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // ── Track (full dashed ring) ─────────────────────────
    _drawDashedArc(
      canvas,
      rect,
      startAngle: -pi / 2,
      sweepAngle: 2 * pi,
      color:      AppColors.textMuted,
    );

    // ── Progress arc ─────────────────────────────────────
    if (progress > 0) {
      _drawDashedArc(
        canvas,
        rect,
        startAngle: -pi / 2,
        sweepAngle: 2 * pi * progress,
        color:      AppColors.accent,
      );
    }
  }

  void _drawDashedArc(
    Canvas canvas,
    Rect rect, {
    required double startAngle,
    required double sweepAngle,
    required Color color,
  }) {
    final paint = Paint()
      ..color       = color
      ..style       = PaintingStyle.stroke
      ..strokeWidth = AppDimensions.donutStrokeWidth
      ..strokeCap   = StrokeCap.round;

    // ── Dash config ───────────────────────────────────────
    // Exactly 8 evenly-spaced blobs around the full circle, with a
    // wide gap between them for clear separation.
    const segmentCount = 8;
    const dashFraction = 0.4; // portion of each segment that's a visible blob
    const step         = (2 * pi) / segmentCount;
    const dashAngle    = step * dashFraction;

    double angle = startAngle;
    final end    = startAngle + sweepAngle;

    while (angle < end) {
      final dashEnd = (angle + dashAngle).clamp(angle, end);
      canvas.drawArc(rect, angle, dashEnd - angle, false, paint);
      angle += step;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

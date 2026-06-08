import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';

/// ─────────────────────────────────────────────────────────────
///  REMAINING RING
///  Dashed oval countdown shown on the Clocked In screen.
///  Swap [totalShift] to change the full-shift reference duration.
/// ─────────────────────────────────────────────────────────────
class RemainingRing extends StatelessWidget {
  final Duration remaining;

  /// Used to compute how full the dashed ring appears.
  static const Duration totalShift = Duration(hours: 8);

  const RemainingRing({super.key, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  AppDimensions.ovalWidth + 20,
      height: AppDimensions.ovalHeight + 20,
      child: CustomPaint(
        painter: _DashedOvalPainter(
          progress: (remaining.inSeconds / totalShift.inSeconds).clamp(0.0, 1.0),
          color:    AppColors.accent,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormatter.duration(remaining),
                style: AppTextStyles.remainingLarge,
              ),
              Text('remaining', style: AppTextStyles.remainingSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedOvalPainter extends CustomPainter {
  final double progress;
  final Color  color;

  const _DashedOvalPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap   = StrokeCap.round;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);

    // Full dashed outline
    _drawDashedOval(canvas, rect, paint.copyWith(color: color.withOpacity(0.2)));

    // Progress arc (sweeps counter-clockwise from top)
    _drawDashedOval(canvas, rect, paint, progress: progress);
  }

  void _drawDashedOval(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    double progress = 1.0,
  }) {
    const dashCount   = 32;
    const dashLength  = 0.06; // fraction of full sweep per dash
    const gapLength   = 0.03;
    const totalLength = dashLength + gapLength;

    final sweepAngle = 2 * 3.14159265 * progress;
    double angle = -3.14159265 / 2; // start at top

    for (int i = 0; i < dashCount; i++) {
      final start = angle;
      final end   = angle + dashLength * 2 * 3.14159265;

      if (start > -3.14159265 / 2 + sweepAngle) break;

      final clampedEnd = end.clamp(
        -3.14159265 / 2,
        -3.14159265 / 2 + sweepAngle,
      );

      canvas.drawArc(rect, start, clampedEnd - start, false, paint);
      angle += totalLength * 2 * 3.14159265;
    }
  }

  @override
  bool shouldRepaint(_DashedOvalPainter old) =>
      old.progress != progress || old.color != color;
}

extension on Paint {
  Paint copyWith({Color? color}) {
    return Paint()
      ..color       = color ?? this.color
      ..style       = style
      ..strokeWidth = strokeWidth
      ..strokeCap   = strokeCap;
  }
}

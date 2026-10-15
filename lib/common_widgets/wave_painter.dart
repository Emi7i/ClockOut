import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

/// ─────────────────────────────────────────────────────────────
///  WAVE PAINTER
///  Draws the wavy top edge used by [AppNavBar].
///  Adjust the peak/valley points below to change the wave's
///  shape without touching any other file.
/// ─────────────────────────────────────────────────────────────
class WavePainter extends CustomPainter {
  final Color color;

  const WavePainter({this.color = AppColors.navBar});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // ── Two symmetric hills, centered above the two nav icons ──
    // (which sit at 25% / 75% width via the Row's spaceAround layout).
    // The dip between the two hills goes all the way down to [valleyY],
    // but the outer edges only ease down to the shallower [edgeY] so the
    // hills read as continuing off the sides rather than dropping into a
    // full valley. Every peak/valley below is a true turning point with a
    // flat tangent, so the curve reads as one continuous wave.
    const double peakY   = 0;
    final double valleyY = AppDimensions.waveHeight;
    final double edgeY   = AppDimensions.waveHeight * 0.35;

    final double x0 = 0;
    final double x1 = size.width * 0.25;
    final double x2 = size.width * 0.50;
    final double x3 = size.width * 0.75;
    final double x4 = size.width;

    path.moveTo(x0, edgeY);
    _waveSegment(path, x0, edgeY,   x1, peakY);   // left edge (shallow) → hill 1 peak
    _waveSegment(path, x1, peakY,   x2, valleyY); // hill 1 peak → middle valley (full dip)
    _waveSegment(path, x2, valleyY, x3, peakY);   // middle valley → hill 2 peak
    _waveSegment(path, x3, peakY,   x4, edgeY);   // hill 2 peak → right edge (shallow)

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  /// Draws one smooth wave segment from (x0, y0) to (x1, y1), flattening
  /// the tangent at both ends by keeping each control point's y level with
  /// its nearest endpoint — the standard trick for a sine-like S-curve.
  void _waveSegment(Path path, double x0, double y0, double x1, double y1) {
    final midX = (x0 + x1) / 2;
    path.cubicTo(midX, y0, midX, y1, x1, y1);
  }

  @override
  bool shouldRepaint(WavePainter old) => old.color != color;
}

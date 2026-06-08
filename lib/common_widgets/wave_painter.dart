import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

/// ─────────────────────────────────────────────────────────────
///  WAVE PAINTER
///  Draws the wavy top edge used by [AppNavBar].
///  Adjust the quadratic Bézier control points below to
///  change the wave's shape without touching any other file.
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

    // ── Wave starts at the left at [waveHeight] from the top ─
    path.moveTo(0, AppDimensions.waveHeight);

    // ── Each Q() = one wave bump ──────────────────────────────
    // Q(controlX, controlY, endX, endY)
    path.quadraticBezierTo(size.width * 0.14,  2,  size.width * 0.25, 14);
    path.quadraticBezierTo(size.width * 0.36, 22,  size.width * 0.50, 10);
    path.quadraticBezierTo(size.width * 0.64,  0,  size.width * 0.75, 14);
    path.quadraticBezierTo(size.width * 0.86, 22,  size.width,         8);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter old) => old.color != color;
}

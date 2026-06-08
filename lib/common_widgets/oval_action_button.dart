import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

/// ─────────────────────────────────────────────────────────────
///  OVAL ACTION BUTTON
///  The crosshatch-textured oval used for Clock In / Clock Out.
///
///  Parameters:
///    [label]     – text displayed inside the oval
///    [onPressed] – callback when tapped
///    [width]     – oval width  (default: AppDimensions.ovalWidth)
///    [height]    – oval height (default: AppDimensions.ovalHeight)
///    [strokeColor]  – border + hatch colour
///    [hatchOpacity] – opacity of the crosshatch fill (0.0–1.0)
/// ─────────────────────────────────────────────────────────────
class OvalActionButton extends StatelessWidget {
  final String    label;
  final VoidCallback onPressed;
  final double    width;
  final double    height;
  final Color     strokeColor;
  final double    hatchOpacity;

  const OvalActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width        = AppDimensions.ovalWidth,
    this.height       = AppDimensions.ovalHeight,
    this.strokeColor  = AppColors.accent,
    this.hatchOpacity = 0.30,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width:  width,
        height: height,
        child: CustomPaint(
          painter: _OvalButtonPainter(
            strokeColor:  strokeColor,
            hatchOpacity: hatchOpacity,
          ),
          child: Center(
            child: Text(label, style: AppTextStyles.ovalButton),
          ),
        ),
      ),
    );
  }
}

// ── Internal painter ──────────────────────────────────────────
class _OvalButtonPainter extends CustomPainter {
  final Color  strokeColor;
  final double hatchOpacity;

  const _OvalButtonPainter({
    required this.strokeColor,
    required this.hatchOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // ── Clip to oval so hatching stays inside ────────────
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, Radius.elliptical(size.width, size.height)),
    );

    // ── Diagonal hatch lines ──────────────────────────────
    final hatchPaint = Paint()
      ..color       = strokeColor.withOpacity(hatchOpacity)
      ..strokeWidth = 1.0;

    const spacing = 6.0;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    final count    = (diagonal / spacing).ceil() + 4;

    for (int i = -count; i < count; i++) {
      final offset = i * spacing.toDouble();
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        hatchPaint,
      );
    }

    canvas.restore();

    // ── Oval border ───────────────────────────────────────
    final borderPaint = Paint()
      ..color       = strokeColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(rect, borderPaint);
  }

  @override
  bool shouldRepaint(_OvalButtonPainter old) =>
      old.strokeColor != strokeColor || old.hatchOpacity != hatchOpacity;
}

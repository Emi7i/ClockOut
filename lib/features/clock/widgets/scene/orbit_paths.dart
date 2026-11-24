import 'package:material_ui/material_ui.dart';

/// One orbit of the Night scene: a single cubic Bézier, in design pixels of
/// the 388×764 frame (top-anchored, so the orbits keep their distance from the
/// top of the screen).
///
/// These are real vector path data, fitted to the three orbits of the Figma
/// "Paths" frame (6:581) to within a pixel. The Figma file drew each orbit as a
/// solid piece plus a dashed piece; here it is ONE path that a body rides, with
/// the solid / dashed split decided by the body's progress.
class OrbitCurve {
  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  const OrbitCurve(this.start, this.control1, this.control2, this.end);

  /// The curve as a [Path], with every coordinate multiplied by [scale].
  Path toPath(double scale) {
    Offset s(Offset o) => o * scale;
    return Path()
      ..moveTo(s(start).dx, s(start).dy)
      ..cubicTo(s(control1).dx, s(control1).dy, s(control2).dx, s(control2).dy,
          s(end).dx, s(end).dy);
  }
}

/// Where along its orbit (0..1 of the path's length) a body sits for a stat
/// [progress] (0..1): the stat's range is squeezed in between
/// [OrbitCurves.trackPadding] at each end. The orbit itself, solid and dashed,
/// is still drawn from edge to edge.
double trackFraction(
  double progress, {
  double padding = OrbitCurves.trackPadding,
}) =>
    padding + progress.clamp(0.0, 1.0) * (1 - 2 * padding);

abstract final class OrbitCurves {
  /// Top orbit: the Vacation comet.
  static const top = OrbitCurve(
    Offset(0, 220.5),
    Offset(119.216, 117.373),
    Offset(275.76, 125.981),
    Offset(390.5, 214.0),
  );

  /// Middle orbit: the Remote comet.
  static const middle = OrbitCurve(
    Offset(-3, 347.875),
    Offset(119.804, 243.794),
    Offset(273.733, 254.503),
    Offset(387.5, 341.375),
  );

  /// Bottom orbit: the moon (Bonus).
  static const bottom = OrbitCurve(
    Offset(0, 472.875),
    Offset(117.3, 372.664),
    Offset(272.637, 375.924),
    Offset(390.5, 466.375),
  );

  /// Line style, in design pixels (as drawn in Figma).
  static const double strokeWidth = 3;
  static const double dashLength = 3;
  static const double gapLength = 4;

  /// Keeps the bodies on screen. A stat of 0 puts the body this far (as a
  /// fraction of the orbit's length) from the start of its orbit, and a stat
  /// of 1 the same distance from the end, so none of them ever sits at the
  /// screen edge. 0.125 is where the moon sits at 1 h of its 8 h track.
  /// Change it here.
  static const double trackPadding = 0.125;

  /// Where Figma draws each body, as a fraction of its orbit's length (where
  /// the solid line meets the dashed one). Only a visual reference: the real
  /// positions come from the stats. The comets are drawn so that, at these
  /// positions, they look exactly as designed; anywhere else they turn with
  /// the orbit's direction.
  static const double topFigma = 0.528;
  static const double middleFigma = 0.688;
  static const double bottomFigma = 0.309;
}

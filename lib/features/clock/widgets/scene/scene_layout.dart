import 'package:material_ui/material_ui.dart';

/// Maps the Figma frame (388×764 design pixels) onto the real screen.
///
/// Everything scales uniformly with the screen WIDTH. Elements anchored to
/// the top keep their distance from the top; elements anchored to the bottom
/// (Earth, atmosphere, horizon, aurora, caption) keep their distance from the
/// bottom, so taller phones (390×844) simply get more sky in between.
class SceneLayout {
  static const double designWidth = 388;
  static const double designHeight = 764;

  final Size size;
  final double scale;

  /// Extra vertical offset applied to bottom-anchored elements.
  final double bottomShift;

  SceneLayout(this.size)
      : scale = size.width / designWidth,
        bottomShift = size.height - designHeight * (size.width / designWidth);

  /// Design pixels → screen pixels.
  double s(double v) => v * scale;

  /// Rect for a layer given in design coordinates.
  Rect rect(double left, double top, double w, double h,
      {bool bottomAnchored = false}) {
    return Rect.fromLTWH(
      left * scale,
      top * scale + (bottomAnchored ? bottomShift : 0),
      w * scale,
      h * scale,
    );
  }

  /// Positions [child] at a design-coordinate rect inside a [Stack].
  Widget place(
    double left,
    double top,
    double w,
    double h, {
    bool bottomAnchored = false,
    required Widget child,
  }) {
    return Positioned.fromRect(
      rect: rect(left, top, w, h, bottomAnchored: bottomAnchored),
      child: child,
    );
  }
}

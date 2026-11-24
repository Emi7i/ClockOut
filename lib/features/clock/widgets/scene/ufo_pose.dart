import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'scene_timeline.dart';

/// Geometry of the UFO group in the 388×764 design frame, and where it sits
/// at each moment of the shift. Pure math, no widgets.
///
/// The group (saucer + beam) is one box that is translated, rotated and
/// scaled about its own centre, exactly like the Figma "ufo" frame.
abstract final class UfoGeometry {
  /// The group's box in the design frame.
  static const Rect box = Rect.fromLTWH(130.6, 215.3, 125.05, 148.97);

  /// Saucer image inside the box (box-relative).
  static const Rect saucer = Rect.fromLTWH(1.2, 0, 123.9, 41.7);

  /// Beam image inside the box (box-relative).
  static const Rect beam = Rect.fromLTWH(-5.33, 11.86, 136.7, 121.7);

  /// The Earth's outline: an ellipse in the design frame (bottom-anchored).
  static const Offset earthCenter = Offset(194.5, 769);
  static const double earthRadiusX = 196.5;
  static const double earthRadiusY = 176;

  /// How far the ring floats above the Earth's outline
  static const double ringClearance = 30;

  /// The dashed ring: an ellipse concentric with the Earth, [ringClearance]
  /// larger on every side, so it never touches the globe.
  static const Offset ringCenter = earthCenter;
  static const double ringRadiusX = earthRadiusX + ringClearance;
  static const double ringRadiusY = earthRadiusY + ringClearance;

  /// x of the orbit's left end (the right end is its mirror image).
  static const double orbitLeftX = 34;

  /// The pivot: the group's centre, in the design frame.
  static Offset get boxCenter => box.center;

  /// The saucer's centre relative to the group's box (NOT the design frame).
  static Offset get saucerCenter => saucer.center;

  /// Point on the ring at parameter angle [a] (screen coordinates, y down).
  static Offset ringPoint(double a) =>
      ringCenter + Offset(math.cos(a) * ringRadiusX, math.sin(a) * ringRadiusY);

  /// Heading of the UFO travelling clockwise along the ring at [a]: its
  /// rotation, so it banks along the tangent (0 = level at the very top).
  static double ringTangent(double a) =>
      math.atan2(math.cos(a) * ringRadiusY, -math.sin(a) * ringRadiusX);

  /// Parameter angle of the orbit's left end (upper-left of the ring).
  static double get orbitStartAngle =>
      -math.acos(((orbitLeftX - ringCenter.dx) / ringRadiusX).clamp(-1.0, 1.0));

  /// Mirror image on the right.
  static double get orbitEndAngle => -math.pi - orbitStartAngle;
}

/// Where the UFO group is: a translation (design px), a rotation (rad), a
/// uniform scale, and how much of the screen's extra height (taller than the
/// design) the translation absorbs — 0 at the start above the card, 1 once it
/// sits on the Earth-anchored ring.
class UfoPose {
  final Offset translation;
  final double rotation;
  final double scale;
  final double bottomBlend;

  const UfoPose(this.translation, this.rotation, this.scale, this.bottomBlend);

  /// The Figma intro keyframes, untouched (they end on the original circle).
  factory UfoPose._figma(double t) => UfoPose(
        Offset(ShiftTimeline.translateX(t), ShiftTimeline.translateY(t)),
        ShiftTimeline.rotation(t),
        ShiftTimeline.scale(t),
        0,
      );

  /// The intro at progress [t] (0..1). Follows the Figma path, but is
  /// steered over the last stretch so that it lands exactly on the left end
  /// of the (higher) ring, with the tangent tilt.
  factory UfoPose.intro(double t) {
    final figma = UfoPose._figma(t);
    final w =
        (figma.translation.dy / ShiftTimeline.endTranslateY).clamp(0.0, 1.0);

    final end = UfoPose._figma(1);
    final landing = UfoPose.atSaucer(
      UfoGeometry.ringPoint(UfoGeometry.orbitStartAngle),
      UfoGeometry.ringTangent(UfoGeometry.orbitStartAngle),
      ShiftTimeline.endScale,
      1,
    );
    return UfoPose(
      figma.translation + (landing.translation - end.translation) * w,
      figma.rotation + (landing.rotation - end.rotation) * w,
      figma.scale,
      w,
    );
  }

  /// The saucer's centre in the design frame under this pose.
  Offset get saucerCenter {
    final o = UfoGeometry.boxCenter;
    // Saucer centre relative to the box centre (the pivot).
    final p = UfoGeometry.saucerCenter - UfoGeometry.box.size.center(Offset.zero);
    final cos = math.cos(rotation), sin = math.sin(rotation);
    final r = Offset(
      (p.dx * cos - p.dy * sin) * scale,
      (p.dx * sin + p.dy * cos) * scale,
    );
    return o + translation + r;
  }

  /// A pose that puts the saucer's centre at [point] (design frame) with the
  /// given rotation and scale.
  factory UfoPose.atSaucer(
      Offset point, double rotation, double scale, double bottomBlend) {
    final zero = UfoPose(Offset.zero, rotation, scale, bottomBlend);
    return UfoPose(point - zero.saucerCenter, rotation, scale, bottomBlend);
  }
}

/// The orbit along the top arc of the ring.
abstract final class UfoOrbit {
  /// Parameter angle on the ring for [f] in 0..1 (0 = left end, the intro's
  /// landing point; 1 = the mirrored point on the right).
  static double angleAt(double f) {
    final c = f.clamp(0.0, 1.0);
    return UfoGeometry.orbitStartAngle +
        (UfoGeometry.orbitEndAngle - UfoGeometry.orbitStartAngle) * c;
  }

  /// The saucer's position for [f], in the design frame.
  static Offset saucerAt(double f) => UfoGeometry.ringPoint(angleAt(f));

  static UfoPose poseAt(double f) {
    final a = angleAt(f);
    return UfoPose.atSaucer(
      UfoGeometry.ringPoint(a),
      UfoGeometry.ringTangent(a),
      ShiftTimeline.endScale,
      1,
    );
  }
}

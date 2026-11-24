import 'package:material_ui/material_ui.dart';

/// One keyframe of a Figma timeline. [ease] shapes the segment that STARTS
/// at this key (that is how the CSS export defines it).
class Keyframe {
  final double t;
  final double value;
  final Curve ease;
  const Keyframe(this.t, this.value, [this.ease = Curves.linear]);
}

/// Value of [keys] at normalized time [t] (0..1). Holds the first / last
/// value outside the range.
double sampleTrack(List<Keyframe> keys, double t) {
  if (t <= keys.first.t) return keys.first.value;
  if (t >= keys.last.t) return keys.last.value;
  for (var i = 0; i < keys.length - 1; i++) {
    final a = keys[i];
    final b = keys[i + 1];
    if (t <= b.t) {
      final f = (t - a.t) / (b.t - a.t);
      return a.value + (b.value - a.value) * a.ease.transform(f);
    }
  }
  return keys.last.value;
}

/// The Day→Night timeline of the Figma "Home – Day" frame (1.396 s).
/// Every layer of the scene reads its state from ONE progress value
/// (0 = Day, 1 = Night) through these tracks.
abstract final class SceneTimeline {
  static const _standard = Cubic(0.4, 0, 0.2, 1);
  static const _symmetric = Cubic(0.5, 0, 0.5, 1);

  static const _atmosphere = [
    Keyframe(0, 1),
    Keyframe(0.13505, 1, _standard),
    Keyframe(0.70136, 0),
    Keyframe(1, 0),
  ];
  static const _stars = [
    Keyframe(0, 0.13, _symmetric),
    Keyframe(0.27946, 0.2, _symmetric),
    Keyframe(0.71494, 1),
    Keyframe(1, 1),
  ];
  static const _earthGlobe = [
    Keyframe(0, 1),
    Keyframe(0.38416, 1),
    Keyframe(0.6326, 0),
    Keyframe(1, 0),
  ];
  static const _earthDrift = [
    Keyframe(0, -21),
    Keyframe(0.02621, -21),
    Keyframe(0.18831, -37),
    Keyframe(0.6326, -102),
    Keyframe(0.78031, -169),
    Keyframe(1, -169),
  ];
  static const _horizon = [
    Keyframe(0, 0),
    Keyframe(0.27946, 0, _standard),
    Keyframe(0.55001, 1),
    Keyframe(1, 1),
  ];
  static const _nebula = [
    Keyframe(0, 0),
    Keyframe(0.60539, 0, _standard),
    Keyframe(0.84414, 1),
    Keyframe(1, 1),
  ];
  static const _orbits = [
    Keyframe(0, 0),
    Keyframe(0.55021, 0, _symmetric),
    Keyframe(0.72872, 1),
    Keyframe(1, 1),
  ];
  static const _ufoAndCard = [
    Keyframe(0, 1, _symmetric),
    Keyframe(0.14322, 0),
    Keyframe(1, 0),
  ];

  static double atmosphereOpacity(double p) => sampleTrack(_atmosphere, p);
  static double starsOpacity(double p) => sampleTrack(_stars, p);
  static double earthOpacity(double p) => sampleTrack(_earthGlobe, p);

  /// Vertical drift of the surface/clouds texture, in design pixels.
  static double earthDriftY(double p) => sampleTrack(_earthDrift, p);
  static double horizonOpacity(double p) => sampleTrack(_horizon, p);
  static double nebulaOpacity(double p) => sampleTrack(_nebula, p);

  /// Orbit paths, comets and moon.
  static double orbitsOpacity(double p) => sampleTrack(_orbits, p);

  /// UFO, beam, dashed ring and Start Shift card fade out first.
  static double ufoAndCardOpacity(double p) => sampleTrack(_ufoAndCard, p);
}

/// The "Start Shift" UFO timeline of the Figma UFO frame (3 s, played once,
/// forward). Every layer reads its state from ONE intro progress value
/// (0..1) through these tracks.
abstract final class ShiftTimeline {
  static const _symmetric = Cubic(0.5, 0, 0.5, 1);
  static const _overshoot = Cubic(0, 0.284, 0, 1.284);

  /// Final intro translation, in design pixels (also the divisor for the
  /// "how far has it travelled" blend used on taller screens).
  static const double endTranslateY = 391.509857;

  /// Intro progress at which everything has settled: the UFO has landed and
  /// the beam and ring are fully in. The last 12.6% of the timeline is a
  /// hold, so playing the intro in reverse starts from here, not from 1,
  /// to avoid a dead pause before the UFO starts to move.
  static const double settledAt = 0.87453;
  static const double endRotation = -0.872665;
  static const double endScale = 0.42;

  static const _tx = [
    Keyframe(0, 0),
    Keyframe(0.23183, 0),
    Keyframe(0.45297, 246.214447),
    Keyframe(0.50630, 247.287048),
    Keyframe(0.59237, -123.712982),
    Keyframe(0.87432, -152.155746),
    Keyframe(1, -152.155746),
  ];
  static const _ty = [
    Keyframe(0, 0),
    Keyframe(0.23183, 0),
    Keyframe(0.45297, 68.665894),
    Keyframe(0.50630, 101.583008),
    Keyframe(0.59237, 314.583008),
    Keyframe(0.87432, endTranslateY),
    Keyframe(1, endTranslateY),
  ];
  static const _rot = [
    Keyframe(0, 0),
    Keyframe(0.23011, 0, _symmetric),
    Keyframe(0.43093, 0.106429, _symmetric),
    Keyframe(0.595, -0.471808, _symmetric),
    Keyframe(0.76802, -0.14802, _symmetric),
    Keyframe(0.87432, endRotation),
    Keyframe(1, endRotation),
  ];
  static const _scale = [
    Keyframe(0, 1),
    Keyframe(0.23183, 1, _overshoot),
    Keyframe(0.87432, endScale),
    Keyframe(1, endScale),
  ];
  static const _beam = [
    Keyframe(0, 0),
    Keyframe(0.76792, 0, _symmetric),
    Keyframe(0.83892, 1),
    Keyframe(1, 1),
  ];
  static const _ring = [
    Keyframe(0, 0),
    Keyframe(0.76712, 0, _symmetric),
    Keyframe(0.87453, 1),
    Keyframe(1, 1),
  ];
  static const _signScaleY = [
    Keyframe(0, 1),
    Keyframe(0.00022, 1, _symmetric),
    Keyframe(0.13934, 0),
    Keyframe(1, 0),
  ];
  static const _signLift = [
    Keyframe(0, 0),
    Keyframe(0.00022, 0),
    Keyframe(0.13934, -90.979), // -88.08 minus the frame's 2.899 base offset
    Keyframe(1, -90.979),
  ];
  static const _signText = [
    Keyframe(0, 1, _symmetric),
    Keyframe(0.00469, 0),
    Keyframe(1, 0),
  ];

  static double translateX(double t) => sampleTrack(_tx, t);
  static double translateY(double t) => sampleTrack(_ty, t);
  static double rotation(double t) => sampleTrack(_rot, t);
  static double scale(double t) => sampleTrack(_scale, t);
  static double beamOpacity(double t) => sampleTrack(_beam, t);
  /// Fade-in of the dashed ring, 0..1 (its final opacity is
  /// [AppConstants.ringOpacity]; apply it where the ring is drawn).
  static double ringFade(double t) => sampleTrack(_ring, t);
  static double signScaleY(double t) => sampleTrack(_signScaleY, t);
  static double signLift(double t) => sampleTrack(_signLift, t);
  static double signTextOpacity(double t) => sampleTrack(_signText, t);
}

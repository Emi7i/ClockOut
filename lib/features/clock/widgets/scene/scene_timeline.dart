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

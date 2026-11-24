import 'package:material_ui/material_ui.dart';

import '../../../../common_widgets/common_widgets.dart';
import 'night_track_values.dart';
import 'orbit_paths.dart';
import 'scene_layout.dart';
import 'scene_timeline.dart';

/// The Night bodies: two comets and the moon, each riding its own orbit with a
/// solid line behind and a dashed line ahead. Where each one sits comes from
/// [values] (0 = start of its orbit, 1 = end).
///
/// They fade in together, on the Figma Paths/Moon timing.
class NightTracks extends StatelessWidget {
  final Animation<double> scene;
  final NightTrackValues values;

  const NightTracks({super.key, required this.scene, required this.values});

  static const _dir = 'assets/home/';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final l = SceneLayout(constraints.biggest);
        // Built once per size; only the opacity follows the scene.
        final tracks = _tracks(l);
        return AnimatedBuilder(
          animation: scene,
          builder: (context, child) {
            final opacity = SceneTimeline.orbitsOpacity(scene.value);
            if (opacity <= 0) return const SizedBox.shrink();
            return Opacity(opacity: opacity, child: child);
          },
          child: tracks,
        );
      },
    );
  }

  Widget _tracks(SceneLayout l) {
    Widget track(
      OrbitCurve curve,
      double progress,
      Widget Function(BuildContext, double heading) body,
    ) {
      return OrbitTrack(
        path: curve.toPath(l.scale),
        progress: trackFraction(progress),
        strokeWidth: OrbitCurves.strokeWidth * l.scale,
        dashLength: OrbitCurves.dashLength * l.scale,
        gapLength: OrbitCurves.gapLength * l.scale,
        bodyBuilder: body,
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        track(
          OrbitCurves.bottom,
          values.bonus,
          (_, __) => _Moon(layout: l),
        ),
        track(
          OrbitCurves.middle,
          values.remote,
          (_, heading) => _Comet(
            layout: l,
            asset: 'comet_b.png',
            size: const Size(201.25, 61),
            head: const Offset(174.2, 36.2),
            turn: heading - _heading(OrbitCurves.middle, OrbitCurves.middleFigma),
          ),
        ),
        track(
          OrbitCurves.top,
          values.vacation,
          (_, heading) => _Comet(
            layout: l,
            asset: 'comet_a.png',
            size: const Size(203.75, 63.75),
            head: const Offset(177.9, 26.2),
            turn: heading - _heading(OrbitCurves.top, OrbitCurves.topFigma),
          ),
        ),
      ],
    );
  }

  /// The orbit's heading where Figma draws its comet (design pixels).
  static double _heading(OrbitCurve curve, double fraction) =>
      pathHeadingAt(curve.toPath(1), fraction);
}

/// The moon, centred on its orbit point.
class _Moon extends StatelessWidget {
  final SceneLayout layout;
  const _Moon({required this.layout});

  static const double _diameter = 84.8;

  @override
  Widget build(BuildContext context) {
    final d = layout.s(_diameter);
    return Transform.translate(
      offset: Offset(-d / 2, -d / 2),
      child: SizedBox(
        width: d,
        height: d,
        child: Image.asset('${NightTracks._dir}moon.png', fit: BoxFit.fill),
      ),
    );
  }
}

/// A comet: its head sits on the orbit point and the tail trails behind. The
/// image was drawn for the orbit's direction at the Figma position, so it is
/// turned about its head by how much the direction differs here ([turn]).
class _Comet extends StatelessWidget {
  final SceneLayout layout;
  final String asset;
  final Size size;

  /// Where the head's glow is inside the image, in design pixels.
  final Offset head;
  final double turn;

  const _Comet({
    required this.layout,
    required this.asset,
    required this.size,
    required this.head,
    required this.turn,
  });

  @override
  Widget build(BuildContext context) {
    final s = layout.scale;
    return Transform(
      // (0, 0) is the orbit point: turn about it.
      alignment: Alignment.topLeft,
      transform: Matrix4.rotationZ(turn),
      child: Transform.translate(
        offset: Offset(-head.dx * s, -head.dy * s),
        child: SizedBox(
          width: size.width * s,
          height: size.height * s,
          child: Image.asset('${NightTracks._dir}$asset', fit: BoxFit.fill),
        ),
      ),
    );
  }
}

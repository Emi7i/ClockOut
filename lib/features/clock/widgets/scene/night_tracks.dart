import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../common_widgets/common_widgets.dart';
import '../../../../core/constants/constants.dart';
import 'night_readout_text.dart';
import 'night_track_values.dart';
import 'orbit_paths.dart';
import 'scene_layout.dart';
import 'scene_timeline.dart';

/// The Night bodies: two comets and the moon, each riding its own orbit with a
/// solid line behind and a dashed line ahead. Where each one sits comes from
/// [values]; each has a short label underneath and can be tapped to select it
/// ([selected] gets a subtle ring, [onSelect] reports a tap).
///
/// They fade in together, on the Figma Paths/Moon timing, and only react to
/// taps once they are (nearly) fully visible.
class NightTracks extends StatelessWidget {
  final Animation<double> scene;
  final NightTrackValues values;
  final ValueListenable<NightBody> selected;
  final ValueChanged<NightBody> onSelect;

  const NightTracks({
    super.key,
    required this.scene,
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  static const _dir = 'assets/home/';

  /// Smallest tap target, in logical pixels.
  static const double minTapTarget = 48;

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
            return IgnorePointer(
              ignoring: opacity < 0.9,
              child: Opacity(opacity: opacity, child: child),
            );
          },
          child: tracks,
        );
      },
    );
  }

  Widget _tracks(SceneLayout l) {
    Widget track(
      NightBody body,
      OrbitCurve curve,
      Widget Function(BuildContext, double heading) art, {
      required double ringDiameter,
    }) {
      return OrbitTrack(
        path: curve.toPath(l.scale),
        progress: trackFraction(values.progressOf(body)),
        strokeWidth: OrbitCurves.strokeWidth * l.scale,
        dashLength: OrbitCurves.dashLength * l.scale,
        gapLength: OrbitCurves.gapLength * l.scale,
        bodyBuilder: (context, heading) => _Marker(
          layout: l,
          body: body,
          ringDiameter: ringDiameter,
          selected: selected,
          onSelect: onSelect,
          art: art(context, heading),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        track(
          NightBody.bonus,
          OrbitCurves.bottom,
          (_, __) => _Moon(layout: l),
          ringDiameter: 100,
        ),
        track(
          NightBody.remote,
          OrbitCurves.middle,
          (_, heading) => _Comet(
            layout: l,
            asset: 'comet_b.png',
            size: const Size(201.25, 61),
            head: const Offset(174.2, 36.2),
            turn: heading -
                _heading(OrbitCurves.middle, OrbitCurves.middleFigma),
          ),
          ringDiameter: 46,
        ),
        track(
          NightBody.vacation,
          OrbitCurves.top,
          (_, heading) => _Comet(
            layout: l,
            asset: 'comet_a.png',
            size: const Size(203.75, 63.75),
            head: const Offset(177.9, 26.2),
            turn: heading - _heading(OrbitCurves.top, OrbitCurves.topFigma),
          ),
          ringDiameter: 46,
        ),
      ],
    );
  }

  /// The orbit's heading where Figma draws its comet (design pixels).
  static double _heading(OrbitCurve curve, double fraction) =>
      pathHeadingAt(curve.toPath(1), fraction);
}

/// A body with everything around it: its art (ignoring touches), the subtle
/// ring while selected, the label underneath and one tap target covering both.
/// (0, 0) is the orbit point, the centre of the body (a comet's head).
class _Marker extends StatelessWidget {
  final SceneLayout layout;
  final NightBody body;
  final double ringDiameter;
  final ValueListenable<NightBody> selected;
  final ValueChanged<NightBody> onSelect;
  final Widget art;

  const _Marker({
    required this.layout,
    required this.body,
    required this.ringDiameter,
    required this.selected,
    required this.onSelect,
    required this.art,
  });

  static const double _labelHeight = 18;
  static const double _labelWidth = 90;

  @override
  Widget build(BuildContext context) {
    final s = layout.scale;
    final ring = ringDiameter * s;
    final label = nightBodyLabel(body);

    // One box that really contains the ring, the label and the tap target
    // (Flutter only hit-tests inside a widget's own bounds). The orbit point
    // is at ([w] / 2, [above]) inside it; the box is shifted so that point
    // lands on the orbit.
    final above = ring / 2 < NightTracks.minTapTarget / 2
        ? NightTracks.minTapTarget / 2
        : ring / 2;
    final labelTop = above + ring / 2 + 4 * s;
    final w = ring > _labelWidth ? ring : _labelWidth;
    final h = labelTop + _labelHeight;

    return Transform.translate(
      offset: Offset(-w / 2, -above),
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The art, with its own origin on the orbit point.
            Positioned(
              left: w / 2,
              top: above,
              child: IgnorePointer(child: art),
            ),
            Positioned(
              left: w / 2 - ring / 2,
              top: above - ring / 2,
              width: ring,
              height: ring,
              child: IgnorePointer(
                child: ValueListenableBuilder<NightBody>(
                  valueListenable: selected,
                  builder: (_, value, __) => AnimatedOpacity(
                    opacity: value == body ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.selectionRing,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: (w - _labelWidth) / 2,
              top: labelTop,
              width: _labelWidth,
              height: _labelHeight,
              // The tap target carries the label for screen readers.
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: AppTextStyles.trackLabel,
                  ),
                ),
              ),
            ),
            // The tap target: the whole box (at least 48 px each way).
            Positioned.fill(
              child: ValueListenableBuilder<NightBody>(
                valueListenable: selected,
                builder: (_, value, __) => Semantics(
                  button: true,
                  selected: value == body,
                  label: label,
                  child: GestureDetector(
                    key: ValueKey('night-body-${body.name}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(body),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

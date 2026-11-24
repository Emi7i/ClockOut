import 'package:material_ui/material_ui.dart';

import '../../../../common_widgets/common_widgets.dart';
import '../../../../core/constants/constants.dart';
import 'scene_layout.dart';
import 'scene_timeline.dart';
import 'ufo_pose.dart';

/// The shift UI layered over the backdrop: dashed ring, UFO with its beam, and
/// the "Start Shift" card.
///
/// Three independent values drive it:
///  * [scene]  (0 Day … 1 Night): the whole group fades out first.
///  * [intro]  (0 … 1): the Figma 3 s "Start Shift" timeline.
///  * [ringTurns]: endless turning of the dashed ring (decorative).
///
/// Once the intro has finished the UFO rides the ring. [orbitFraction]
/// (0 = left end, 1 = right end, null = no shift running) is asked on every
/// frame; it is computed from the persisted clock-in time, never animated.
class ShiftLayer extends StatelessWidget {
  final Animation<double> scene;
  final Animation<double> intro;
  final Animation<double> ringTurns;
  final double? Function()? orbitFraction;
  final VoidCallback? onStartShift;

  const ShiftLayer({
    super.key,
    required this.scene,
    required this.intro,
    required this.ringTurns,
    this.orbitFraction,
    this.onStartShift,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final l = SceneLayout(constraints.biggest);
        return AnimatedBuilder(
          animation: Listenable.merge([scene, intro, ringTurns]),
          builder: (context, _) {
            final fade = SceneTimeline.ufoAndCardOpacity(scene.value);
            if (fade <= 0) return const SizedBox.shrink();
            final t = intro.value;
            return IgnorePointer(
              ignoring: scene.value > 0.02,
              child: Opacity(
                opacity: fade,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    _ring(l, t),
                    _ufo(l, t, t >= 1 ? orbitFraction?.call() : null),
                    _card(l, t),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _ring(SceneLayout l, double t) {
    final opacity = ShiftTimeline.ringFade(t) * AppConstants.ringOpacity;
    if (opacity <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: DashedRing(
        center: Offset(
          UfoGeometry.ringCenter.dx * l.scale,
          UfoGeometry.ringCenter.dy * l.scale + l.bottomShift,
        ),
        radiusX: UfoGeometry.ringRadiusX * l.scale,
        radiusY: UfoGeometry.ringRadiusY * l.scale,
        strokeWidth: 3 * l.scale,
        dashLength: 6 * l.scale,
        color: Colors.white.withValues(alpha: opacity),
        turns: ringTurns.value,
      ),
    );
  }

  Widget _ufo(SceneLayout l, double t, double? orbit) {
    final pose = orbit != null ? UfoOrbit.poseAt(orbit) : UfoPose.intro(t);
    final box = UfoGeometry.box;
    final matrix = Matrix4.identity()
      ..translateByDouble(
        pose.translation.dx * l.scale,
        pose.translation.dy * l.scale + l.bottomShift * pose.bottomBlend,
        0,
        1,
      )
      ..rotateZ(pose.rotation)
      ..scaleByDouble(pose.scale, pose.scale, 1, 1);

    Widget image(String name, Rect r) => Positioned.fromRect(
          rect: Rect.fromLTWH(r.left * l.scale, r.top * l.scale,
              r.width * l.scale, r.height * l.scale),
          child: Image.asset('assets/home/$name', fit: BoxFit.fill),
        );

    final beamOpacity = ShiftTimeline.beamOpacity(t);
    return Positioned.fromRect(
      rect: l.rect(box.left, box.top, box.width, box.height),
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (beamOpacity > 0)
              Opacity(
                opacity: beamOpacity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [image('beam.png', UfoGeometry.beam)],
                ),
              ),
            image('ufo.png', UfoGeometry.saucer),
          ],
        ),
      ),
    );
  }

  Widget _card(SceneLayout l, double t) {
    final scaleY = ShiftTimeline.signScaleY(t);
    if (scaleY <= 0) return const SizedBox.shrink();
    final lift = ShiftTimeline.signLift(t) * l.scale;
    return l.place(
      67,
      295,
      254.583,
      182.828,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(0, lift, 0, 1)
          ..scaleByDouble(1, scaleY, 1, 1),
        child: Semantics(
          button: true,
          label: 'Start Shift',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: t == 0 ? onStartShift : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Glass card art exported from Figma (border + backdrop).
                Image.asset('assets/home/sign.png', fit: BoxFit.fill),
                // The label is a real widget.
                Center(
                  child: Opacity(
                    opacity: ShiftTimeline.signTextOpacity(t),
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(decoration: TextDecoration.none),
                      child: Text(
                        'Start\nShift',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.startShift
                            .copyWith(fontSize: l.s(48)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

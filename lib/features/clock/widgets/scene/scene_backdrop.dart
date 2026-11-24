import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/constants.dart';
import 'scene_layout.dart';
import 'scene_timeline.dart';

/// The sky, Earth, stars, nebula, orbit paths, comets and moon, all driven by
/// ONE [progress] value (0 = Day, 1 = Night) through [SceneTimeline].
///
/// The UFO, beam, ring and Start Shift card are NOT here: they belong to the
/// shift UI and are layered on top by the screens.
class SceneBackdrop extends StatelessWidget {
  final Animation<double> progress;
  const SceneBackdrop({super.key, required this.progress});

  static const _dir = 'assets/home/';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final l = SceneLayout(constraints.biggest);
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.skyTop, AppColors.skyBottom],
            ),
          ),
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, _) => _layers(l, progress.value),
          ),
        );
      },
    );
  }

  Widget _fade(double opacity, Widget child) =>
      Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);

  Widget _img(String name) =>
      Image.asset('$_dir$name', fit: BoxFit.fill, gaplessPlayback: true);

  Widget _layers(SceneLayout l, double p) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Night reveal · nebula (top pink glow + bottom glow)
        l.place(0, 0, 388, 468,
            child:
                _fade(SceneTimeline.nebulaOpacity(p), _img('nebula_top.png'))),
        l.place(0, 146, 361, 503,
            child: _fade(
                SceneTimeline.nebulaOpacity(p), _img('nebula_bottom.png'))),
        // Night reveal · horizon glow
        l.place(0, 503, 388, 261,
            bottomAnchored: true,
            child: _fade(SceneTimeline.horizonOpacity(p), _img('horizon.png'))),
        // Day atmosphere
        l.place(0, 324, 388, 440,
            bottomAnchored: true,
            child: _fade(
                SceneTimeline.atmosphereOpacity(p), _img('atmosphere.png'))),
        // Star field: ONE image
        l.place(0, 13.7, 388, 583,
            child: _fade(SceneTimeline.starsOpacity(p), _img('stars.png'))),
        // Aurora appears with the night reveal
        l.place(0, 543, 388, 159,
            bottomAnchored: true,
            child: _fade(SceneTimeline.nebulaOpacity(p), _img('aurora.png'))),
        // Earth: fixed globe (ellipse) + drifting surface texture
        l.place(-2, 593, 393, 352,
            bottomAnchored: true,
            child: _fade(
              SceneTimeline.earthOpacity(p),
              EarthGlobe(layout: l, driftY: SceneTimeline.earthDriftY(p)),
            )),
        // Orbit paths, comets, moon
        l.place(0, 144.125, 388, 330,
            child: _fade(
              SceneTimeline.orbitsOpacity(p),
              SvgPicture.asset('${_dir}paths.svg', fit: BoxFit.fill),
            )),
        l.place(31, 119, 203.75, 63.75,
            child: _fade(SceneTimeline.orbitsOpacity(p), _img('comet_a.png'))),
        l.place(112, 250, 201.25, 61,
            child: _fade(SceneTimeline.orbitsOpacity(p), _img('comet_b.png'))),
        l.place(78.6, 373.6, 84.8, 84.8,
            child: _fade(SceneTimeline.orbitsOpacity(p), _img('moon.png'))),
      ],
    );
  }
}

/// The fixed elliptical globe with the surface/clouds texture drifting
/// vertically underneath it (Figma: "Earth · fixed globe" +
/// "Surface and clouds · axial drift").
class EarthGlobe extends StatelessWidget {
  final SceneLayout layout;

  /// Drift in design pixels (negative = texture moves up).
  final double driftY;

  const EarthGlobe({super.key, required this.layout, required this.driftY});

  @override
  Widget build(BuildContext context) {
    final l = layout;
    // Texture box inside the globe frame, as laid out in Figma.
    const boxW = 489.0, boxH = 400.0;
    return ClipPath(
      clipper: const _EllipseClipper(),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: l.s(-48),
            top: l.s(-24 + driftY),
            width: l.s(boxW),
            height: l.s(boxH),
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: l.s(boxW * -0.1088),
                    top: l.s(boxH * -0.0153),
                    width: l.s(boxW * 1.2177),
                    height: l.s(boxH * 1.1579),
                    child: Image.asset('assets/home/earth_surface.jpg',
                        fit: BoxFit.fill),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EllipseClipper extends CustomClipper<Path> {
  const _EllipseClipper();
  @override
  Path getClip(Size size) => Path()..addOval(Offset.zero & size);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

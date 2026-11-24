import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/constants.dart';
import 'scene_layout.dart';
import 'scene_timeline.dart';

/// The idle Day layer: UFO above the "Start Shift" card. Fades out first when
/// the scene moves towards Night ([SceneTimeline.ufoAndCardOpacity]).
///
/// The UFO is an exported image; the card and its text are real widgets.
class UfoAndCard extends StatelessWidget {
  final Animation<double> progress;
  final VoidCallback? onStartShift;

  const UfoAndCard({super.key, required this.progress, this.onStartShift});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final l = SceneLayout(constraints.biggest);
        return AnimatedBuilder(
          animation: progress,
          builder: (context, _) {
            final opacity = SceneTimeline.ufoAndCardOpacity(progress.value);
            if (opacity <= 0) return const SizedBox.shrink();
            return Opacity(
              opacity: opacity,
              child: Stack(
                children: [
                  l.place(131.8, 215.3, 123.9, 41.7,
                      child: Image.asset('assets/home/ufo.png',
                          fit: BoxFit.fill)),
                  l.place(67, 295, 254.583, 182.828,
                      child: _StartShiftCard(onTap: onStartShift, layout: l)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StartShiftCard extends StatelessWidget {
  final VoidCallback? onTap;
  final SceneLayout layout;
  const _StartShiftCard({required this.onTap, required this.layout});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Start Shift',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Glass card art exported from Figma (border + backdrop).
            Image.asset('assets/home/sign.png', fit: BoxFit.fill),
            // The label is a real widget.
            Center(
              child: DefaultTextStyle.merge(
                style: const TextStyle(decoration: TextDecoration.none),
                child: Text(
                  'Start\nShift',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.startShift
                      .copyWith(fontSize: layout.s(48)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/constants.dart';
import 'night_readout_text.dart';
import 'night_track_values.dart';
import 'scene_timeline.dart';

/// The Night screen's readout, low on the screen: the name and value of the
/// selected body ("Vacation" / "14 of 22 left"). With Bonus selected it also
/// shows a Convert button, enabled once 8 h or more can be converted.
///
/// It fades in with the Night bodies and only reacts to taps once visible.
/// Pressing Convert only reports [onConvert]; asking for confirmation and
/// doing the conversion is up to the caller.
class NightReadout extends StatelessWidget {
  final Animation<double> scene;
  final NightTrackValues values;
  final ValueListenable<NightBody> selected;
  final VoidCallback onConvert;

  const NightReadout({
    super.key,
    required this.scene,
    required this.values,
    required this.selected,
    required this.onConvert,
  });

  /// Distance from the bottom edge, where the old "15/30 DAYS" placeholder sat.
  static const double bottomInset = 62;

  @override
  Widget build(BuildContext context) {
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
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: bottomInset),
          child: ValueListenableBuilder<NightBody>(
            valueListenable: selected,
            builder: (context, body, _) => AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.bottomCenter,
              child: _Content(
                body: body,
                values: values,
                onConvert: onConvert,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final NightBody body;
  final NightTrackValues values;
  final VoidCallback onConvert;

  const _Content({
    required this.body,
    required this.values,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nightBodyLabel(body).toUpperCase(),
                style: AppTextStyles.readoutTitle,
              ),
              const SizedBox(height: 2),
              Text(
                nightReadout(body, values),
                textAlign: TextAlign.center,
                style: AppTextStyles.readoutValue,
              ),
            ],
          ),
        ),
        if (body == NightBody.bonus) ...[
          const SizedBox(height: 10),
          _ConvertButton(
            enabled: values.bonus.daysReady >= 1,
            onPressed: onConvert,
          ),
        ],
      ],
    );
  }
}

/// The Start Shift card's look in small: glass fill, thin grey border.
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.startCardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.startCardBorder),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ConvertButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ConvertButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Convert 8 hours into 1 vacation day',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onPressed : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 140, minHeight: 48),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: _GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text('Convert', style: AppTextStyles.convertButton),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

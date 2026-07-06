import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';

/// ─────────────────────────────────────────────────────────────
///  REMAINING RING
///  Dashed oval countdown shown on the Clocked In screen.
///  Swap [totalShift] to change the full-shift reference duration.
/// ─────────────────────────────────────────────────────────────
class RemainingRing extends StatelessWidget {
  final Duration remaining;

  const RemainingRing({super.key, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width:  AppDimensions.ovalWidth,
      height: AppDimensions.ovalHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Hand-drawn border image ─────────────────────
          // Tinted to the live accent colour — the asset itself is just a
          // transparent-background stroke.
          Image.asset(
            'assets/ui/timer_border.png',
            width:  AppDimensions.ovalWidth,
            height: AppDimensions.ovalHeight,
            fit:    BoxFit.contain,
            color:  accentColor,
            colorBlendMode: BlendMode.srcIn,
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormatter.duration(remaining),
                style: AppTextStyles.remainingLarge.copyWith(color: accentColor),
              ),
              Text(
                'remaining',
                style: AppTextStyles.remainingSmall.copyWith(color: accentColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Painter removed (now using Image.asset) ───────────────


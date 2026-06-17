import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

/// ─────────────────────────────────────────────────────────────
///  ALARM TOGGLE
///  Styled on/off switch with an "alarm" label.
///
///  Parameters:
///    [isOn]       – current toggle state
///    [onChanged]  – called with the new value when tapped
///    [label]      – text next to the toggle  (default: "alarm")
///    [subLabel]   – optional line below (e.g. countdown text)
/// ─────────────────────────────────────────────────────────────
class AlarmToggle extends StatelessWidget {
  final bool     isOn;
  final ValueChanged<bool> onChanged;
  final String   label;
  final String?  subLabel;

  const AlarmToggle({
    super.key,
    required this.isOn,
    required this.onChanged,
    this.label    = 'alarm',
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Toggle track ────────────────────────────
            GestureDetector(
              onTap: () => onChanged(!isOn),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  56,
                height: 32,
                decoration: BoxDecoration(
                  // filled when on, transparent when off
                  color: isOn ? AppColors.toggleOn : AppColors.toggleOff,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent,
                    width: 2.0,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: isOn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width:  24,
                      height: 24,
                      decoration: BoxDecoration(
                        // knob colour: dark on accent, accent on dark
                        color: isOn
                            ? AppColors.background
                            : AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceSm),
            Text(label, style: AppTextStyles.label),
          ],
        ),

        // ── Optional sub-label (e.g. "next alarm in: 15 min 30 s") ──
        if (subLabel != null) ...[
          const SizedBox(height: AppDimensions.spaceXs),
          Text(subLabel!, style: AppTextStyles.bodyMedium),
        ],
      ],
    );
  }
}

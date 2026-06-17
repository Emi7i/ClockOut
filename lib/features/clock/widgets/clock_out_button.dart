import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK OUT BUTTON
///  The small outlined rectangular button below the alarm toggle.
///  Swap [label] to rename it.
/// ─────────────────────────────────────────────────────────────
class ClockOutButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label; // ← rename here if needed

  const ClockOutButton({
    super.key,
    required this.onPressed,
    this.label = 'Clock Out',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.borderDashed, width: 2.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      ),
      child: Text(label, style: AppTextStyles.outlineButton),
    );
  }
}

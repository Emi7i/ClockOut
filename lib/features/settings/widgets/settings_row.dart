import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

/// ─────────────────────────────────────────────────────────────
///  SETTINGS ROW
///  Icon box + label + optional trailing widget.
///  Add a new settings entry by adding a [SettingsRow] in
///  SettingsScreen — no other changes needed.
/// ─────────────────────────────────────────────────────────────
class SettingsRow extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final VoidCallback onTap;

  /// Optional widget on the far right (e.g. "12h" / "+15" label).
  final Widget?   trailing;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // ── Icon box ────────────────────────────────────
          Container(
            width:  AppDimensions.settingIconBoxSize,
            height: AppDimensions.settingIconBoxSize,
            decoration: BoxDecoration(
              color:        AppColors.accentDim,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(
                color: AppColors.borderDashed,
                width: 1,
                // Dart's Border doesn't support dashes natively;
                // swap this for a CustomPaint dashed border if needed.
              ),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),

          const SizedBox(width: AppDimensions.spaceMd),

          // ── Label ────────────────────────────────────────
          Expanded(
            child: Text(label, style: AppTextStyles.settingLabel),
          ),

          // ── Optional trailing ────────────────────────────
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

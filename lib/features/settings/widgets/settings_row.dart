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
  final Color?    accentColor;

  /// Optional widget on the far right (e.g. "12h" / "+15" label).
  final Widget?   trailing;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.accent;
    final colorDim = color.withOpacity(0.16);

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
              color:        colorDim,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(
                color: AppColors.borderDashed,
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 18),
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

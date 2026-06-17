import 'package:flutter/material.dart';
import '../core/constants/constants.dart';

/// ─────────────────────────────────────────────────────────────
///  APP TOP BAR
///  Gear icon (left) + time string (right).
///  Used on Clock In, Clocked In, and Logs screens.
///
///  Parameters:
///    [timeLabel]      – formatted time string, e.g. "8:55 am"
///    [onSettingsTap]  – opens the Settings screen
///    [trailing]       – optional widget placed on the far right
///                       (e.g. the "change" chip on Logs screen)
/// ─────────────────────────────────────────────────────────────
class AppTopBar extends StatelessWidget {
  final String      timeLabel;
  final VoidCallback onSettingsTap;
  final Widget?     trailing;

  const AppTopBar({
    super.key,
    required this.timeLabel,
    required this.onSettingsTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical:   AppDimensions.screenPaddingV,
      ),
      child: Row(
        children: [
          // ── Settings gear ──────────────────────────────
          GestureDetector(
            onTap: onSettingsTap,
            child: const Icon(
              Icons.settings,          // ← swap icon here
              color: AppColors.accent,
              size: 28,
              semanticLabel: 'Settings',
            ),
          ),

          const Spacer(),

          // ── Time display ───────────────────────────────
          Text(timeLabel, style: AppTextStyles.timeDisplay),

          const Spacer(),

          // ── Optional trailing widget ───────────────────
          if (trailing != null)
            trailing!
          else
            const SizedBox(width: 28), // mirror gear width for centering
        ],
      ),
    );
  }
}

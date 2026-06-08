import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../bloc/clock_bloc.dart';
import '../widgets/remaining_ring.dart';
import '../widgets/clock_out_button.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCKED IN SCREEN
///  Shown while the user is actively clocked in.
///  State: [ClockActive]
/// ─────────────────────────────────────────────────────────────
class ClockedInScreen extends StatelessWidget {
  final VoidCallback      onSettingsTap;
  final int               navIndex;
  final ValueChanged<int> onNavTap;

  const ClockedInScreen({
    super.key,
    required this.onSettingsTap,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClockBloc, ClockState>(
      buildWhen: (_, s) => s is ClockActive,
      builder: (context, state) {
        final active = state as ClockActive;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────
                AppTopBar(
                  timeLabel:     DateFormatter.clockTime(active.currentTime),
                  onSettingsTap: onSettingsTap,
                ),

                // ── Main content ───────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Dashed remaining ring ─────────────
                      RemainingRing(remaining: active.remaining),

                      const SizedBox(height: AppDimensions.spaceLg),

                      // ── Alarm toggle ──────────────────────
                      AlarmToggle(
                        isOn:      active.alarmEnabled,
                        onChanged: (v) => context
                            .read<ClockBloc>()
                            .add(AlarmToggled(enabled: v)),
                        subLabel: active.alarmEnabled && active.nextAlarmIn != null
                            ? 'next alarm in:\n${DateFormatter.countdown(active.nextAlarmIn!)}'
                            : null,
                      ),

                      const SizedBox(height: AppDimensions.spaceMd),

                      // ── Clock Out button ──────────────────
                      ClockOutButton(
                        onPressed: () => context
                            .read<ClockBloc>()
                            .add(const ClockOutRequested()),
                      ),
                    ],
                  ),
                ),

                // ── Bottom nav ─────────────────────────────
                AppNavBar(
                  selectedIndex: navIndex,
                  onItemTapped:  onNavTap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

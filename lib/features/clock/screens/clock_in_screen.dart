import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../bloc/clock_bloc.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK IN SCREEN
///  Shown when the user is NOT clocked in.
///  State: [ClockIdle]
/// ─────────────────────────────────────────────────────────────
class ClockInScreen extends StatelessWidget {
  final VoidCallback onSettingsTap;
  final int          navIndex;
  final ValueChanged<int> onNavTap;

  const ClockInScreen({
    super.key,
    required this.onSettingsTap,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClockBloc, ClockState>(
      buildWhen: (_, s) => s is ClockIdle,
      builder: (context, state) {
        final idle = state as ClockIdle;
        final settingsState = context.watch<SettingsBloc>().state;
        final is12Hour = settingsState is SettingsLoaded ? settingsState.is12HourFormat : true;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar: gear + time ───────────────────
                AppTopBar(
                  timeLabel:     DateFormatter.clockTime(idle.currentTime, is12Hour: is12Hour),
                  onSettingsTap: onSettingsTap,
                ),

                // ── Main content ───────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Clock In button ──────────────────
                      OvalActionButton(
                        label:     'Clock in',  // ← label here
                        onPressed: () => context
                            .read<ClockBloc>()
                            .add(const ClockInRequested()),
                      ),

                      const SizedBox(height: AppDimensions.spaceLg),

                      // ── Alarm toggle ─────────────────────
                      AlarmToggle(
                        isOn:      idle.alarmEnabled,
                        onChanged: (v) => context
                            .read<ClockBloc>()
                            .add(AlarmToggled(enabled: v)),
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

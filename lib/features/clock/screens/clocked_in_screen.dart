import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../settings/bloc/settings_bloc.dart';
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
        final settingsState = context.watch<SettingsBloc>().state;
        final is12Hour = settingsState is SettingsLoaded ? settingsState.is12HourFormat : true;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (active.isRinging) {
              context.read<ClockBloc>().add(const AlarmStopRequested());
            }
          },
            child: SafeArea(
              child: Column(
                children: [
                  // ── Top bar ────────────────────────────────
                  AppTopBar(
                    timeLabel:     DateFormatter.clockTime(active.currentTime, is12Hour: is12Hour),
                    onSettingsTap: onSettingsTap,
                  ),

                  // ── Main content ───────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (active.remaining > Duration.zero) ...[
                          // ── Clocked In Time (Editable) ───────────
                          GestureDetector(
                            onTap: () async {
                              final TimeOfDay? newTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(active.clockedInAt),
                                builder: (context, child) => MediaQuery(
                                  data: MediaQuery.of(context)
                                      .copyWith(alwaysUse24HourFormat: !is12Hour),
                                  child: child!,
                                ),
                              );

                              if (newTime != null && context.mounted) {
                                final now = DateTime.now();
                                // Combine today's date with the selected time
                                var newDateTime = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  newTime.hour,
                                  newTime.minute,
                                );

                                // If the selected time is in the future, assume it was yesterday
                                if (newDateTime.isAfter(now)) {
                                  newDateTime = newDateTime.subtract(const Duration(days: 1));
                                }

                                context.read<ClockBloc>().add(ClockInTimeEdited(newDateTime));
                              }
                            },
                            child: Text(
                              'Clocked in time: ${DateFormatter.clockTime(active.clockedInAt, is12Hour: is12Hour)}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceMd),

                          // ── During shift: Ring + Small button ──
                          RemainingRing(remaining: active.remaining),

                          const SizedBox(height: AppDimensions.spaceLg),

                          AlarmToggle(
                            isOn:      active.alarmEnabled,
                            onChanged: (v) => context
                                .read<ClockBloc>()
                                .add(AlarmToggled(enabled: v)),
                          ),

                          const SizedBox(height: AppDimensions.spaceMd),

                          ClockOutButton(
                            onPressed: () => _confirmClockOut(context),
                          ),
                        ] else ...[
                          // ── After shift: Big button + Alarm countdown ──
                          OvalActionButton(
                            label:     active.isRinging ? 'Stop the Alarm' : 'Clock out',
                            onPressed: () => active.isRinging
                                ? context.read<ClockBloc>().add(const AlarmStopRequested())
                                : _confirmClockOut(context),
                          ),

                          const SizedBox(height: AppDimensions.spaceLg),

                          AlarmToggle(
                            isOn:      active.alarmEnabled,
                            onChanged: (v) => context
                                .read<ClockBloc>()
                                .add(AlarmToggled(enabled: v)),
                            subLabel: active.nextAlarmIn != null
                                ? 'next alarm in: ${DateFormatter.countdown(active.nextAlarmIn!)}'
                                : null,
                          ),
                        ],
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
          ),
        );
      },
    );
  }

  void _confirmClockOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        title: const Text('Clock out', style: AppTextStyles.screenTitle),
        content: const Text(
          'Are you sure you want to clock out?',
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ClockBloc>().add(const ClockOutRequested());
            },
            child: const Text('Clock out', style: AppTextStyles.destructiveButton),
          ),
        ],
      ),
    );
  }
}

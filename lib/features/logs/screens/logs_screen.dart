import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/log_entry.dart';
import '../bloc/logs_bloc.dart';
import '../widgets/donut_chart.dart';
import '../widgets/log_list_tile.dart';

/// ─────────────────────────────────────────────────────────────
///  LOGS SCREEN
///  Donut progress ring + scrollable log list.
///  State: [LogsLoaded]
/// ─────────────────────────────────────────────────────────────
class LogsScreen extends StatelessWidget {
  final VoidCallback      onSettingsTap;
  final int               navIndex;
  final ValueChanged<int> onNavTap;

  const LogsScreen({
    super.key,
    required this.onSettingsTap,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LogsBloc, LogsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar with edit toggle ────────────────
                AppTopBar(
                  timeLabel:     DateFormatter.clockTime(DateTime.now()),
                  onSettingsTap: onSettingsTap,
                  trailing: switch (state) {
                    LogsLoaded() => _EditModeChip(
                        isEditMode: state.isEditMode,
                        onTap: () => context
                            .read<LogsBloc>()
                            .add(const LogsEditModeToggled()),
                      ),
                    _ => const SizedBox(width: 22),
                  },
                ),

                // ── Body ───────────────────────────────────
                Expanded(
                  child: switch (state) {
                    LogsLoading() => Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    LogsError(:final message) => Center(
                        child: Text(message, style: AppTextStyles.bodyMedium),
                      ),
                    LogsLoaded() => _LoadedBody(state: state),
                  },
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

// ── Loaded body ───────────────────────────────────────────────
class _LoadedBody extends StatelessWidget {
  final LogsLoaded state;

  const _LoadedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Donut progress chart ───────────────────────────
        // Tap to switch between weekly and monthly stats.
        GestureDetector(
          onTap: () => context.read<LogsBloc>().add(const LogsPeriodToggled()),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
            child: DonutChart(
              hoursWorked: state.hoursWorked,
              hoursTarget: state.hoursTarget,
              progress:    state.progress,
              periodLabel: state.isWeeklyView ? 'hours this week' : 'hours this month',
            ),
          ),
        ),

        // ── Scrollable log list ────────────────────────────
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH,
            ),
            decoration: BoxDecoration(
              color:        AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: state.entries.isEmpty
                ? Center(
                    child: Text(
                      'No logs yet',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceMd,
                      vertical:   AppDimensions.spaceSm,
                    ),
                    itemCount: state.entries.length,
                    itemBuilder: (context, i) {
                      final entry = state.entries[i];
                      return LogListTile(
                        entry: entry,
                        onTap: state.isEditMode
                            ? () => _showEditLogDialog(context, entry)
                            : null,
                      );
                    },
                  ),
          ),
        ),

        const SizedBox(height: AppDimensions.spaceMd),
      ],
    );
  }
}

/// Opens a dialog letting the user pick new start/end times for [entry].
void _showEditLogDialog(BuildContext context, LogEntry entry) {
  final logsBloc = context.read<LogsBloc>();
  DateTime start = entry.clockedInTime ?? entry.date;
  DateTime end   = entry.clockedOutTime ?? entry.date;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> pickStart() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(start),
          );
          if (picked == null) return;
          setState(() {
            start = DateTime(start.year, start.month, start.day, picked.hour, picked.minute);
            // Keep the end time on/after the new start time.
            if (!end.isAfter(start)) {
              end = start.add(const Duration(hours: 1));
            }
          });
        }

        Future<void> pickEnd() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(end),
          );
          if (picked == null) return;
          setState(() {
            var newEnd = DateTime(start.year, start.month, start.day, picked.hour, picked.minute);
            // Assume an overnight shift if the end time-of-day is before start.
            if (!newEnd.isAfter(start)) {
              newEnd = newEnd.add(const Duration(days: 1));
            }
            end = newEnd;
          });
        }

        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Edit log', style: AppTextStyles.bodyLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EditTimeRow(label: 'Start', time: start, onTap: pickStart),
              const SizedBox(height: AppDimensions.spaceSm),
              _EditTimeRow(label: 'End', time: end, onTap: pickEnd),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: AppTextStyles.bodySmall),
            ),
            TextButton(
              onPressed: () {
                logsBloc.add(LogEntryEdited(
                  original:        entry,
                  newClockedInTime:  start,
                  newClockedOutTime: end,
                ));
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Save',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

// ── Edit dialog time row ────────────────────────────────────────
class _EditTimeRow extends StatelessWidget {
  final String       label;
  final DateTime     time;
  final VoidCallback onTap;

  const _EditTimeRow({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            Row(
              children: [
                Text(
                  DateFormatter.clockTime(time),
                  style: AppTextStyles.bodyMedium.copyWith(color: accentColor),
                ),
                const SizedBox(width: AppDimensions.spaceXs),
                Icon(Icons.access_time_rounded, size: 18, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit toggle chip ────────────────────────────────────────────
class _EditModeChip extends StatelessWidget {
  final bool         isEditMode;
  final VoidCallback onTap;

  const _EditModeChip({required this.isEditMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color:        Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(isEditMode ? 'done' : 'edit', style: AppTextStyles.chipButton),
      ),
    );
  }
}

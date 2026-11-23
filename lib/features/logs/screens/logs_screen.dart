import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/log_entry.dart';
import '../../settings/bloc/settings_bloc.dart';
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
        final settingsState = context.watch<SettingsBloc>().state;
        final is12Hour = settingsState is SettingsLoaded ? settingsState.is12HourFormat : true;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar with edit toggle ────────────────
                AppTopBar(
                  timeLabel:     DateFormatter.clockTime(DateTime.now(), is12Hour: is12Hour),
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
                            ? () => _editLog(context, entry)
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


void _editLog(BuildContext context, LogEntry entry) {
  final logsBloc = context.read<LogsBloc>();
  final settingsState = context.read<SettingsBloc>().state;

  showEditLogDialog(
    context,
    start:    entry.clockedInTime ?? entry.date,
    end:      entry.clockedOutTime ?? entry.date,
    is12Hour: settingsState is SettingsLoaded ? settingsState.is12HourFormat : true,
    onSave: (start, end) => logsBloc.add(LogEntryEdited(
      original:          entry,
      newClockedInTime:  start,
      newClockedOutTime: end,
    )),
    onDelete: () => logsBloc.add(LogEntryDeleted(entry)),
  );
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

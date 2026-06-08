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
                // ── Top bar with "change" chip ─────────────
                AppTopBar(
                  timeLabel:     DateFormatter.clockTime(DateTime.now()),
                  onSettingsTap: onSettingsTap,
                  trailing: switch (state) {
                    LogsLoaded() => _ChangePeriodChip(
                        label: state.isWeeklyView ? 'weekly' : 'monthly',
                        onTap: () => context
                            .read<LogsBloc>()
                            .add(const LogsPeriodToggled()),
                      ),
                    _ => const SizedBox(width: 22),
                  },
                ),

                // ── Body ───────────────────────────────────
                Expanded(
                  child: switch (state) {
                    LogsLoading() => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceMd),
          child: DonutChart(
            hoursWorked: state.hoursWorked,
            hoursTarget: state.hoursTarget,
            progress:    state.progress,
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
                    itemBuilder: (_, i) =>
                        LogListTile(entry: state.entries[i]),
                  ),
          ),
        ),

        const SizedBox(height: AppDimensions.spaceMd),
      ],
    );
  }
}

// ── "change" chip ─────────────────────────────────────────────
class _ChangePeriodChip extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;

  const _ChangePeriodChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color:        AppColors.accent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(label, style: AppTextStyles.chipButton),
      ),
    );
  }
}

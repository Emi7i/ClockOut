import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../bloc/settings_bloc.dart';
import '../widgets/settings_row.dart';
import '../widgets/delete_logs_button.dart';

/// ─────────────────────────────────────────────────────────────
///  SETTINGS SCREEN
///  Back arrow + title, three setting rows, delete button.
/// ─────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  final VoidCallback      onBack;
  final int               navIndex;
  final ValueChanged<int> onNavTap;

  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: back arrow + title ─────────────
                _SettingsHeader(onBack: onBack),

                const SizedBox(height: AppDimensions.spaceLg),

                // ── Setting rows ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingH,
                  ),
                  child: Column(
                    children: [
                      // ── Pick accent colour ─────────────
                      SettingsRow(
                        icon:    Icons.palette_outlined,  // ← swap icon
                        label:   'Pick accent Color',     // ← swap label
                        onTap:   () => _showColorPicker(context),
                      ),

                      const SizedBox(height: AppDimensions.spaceLg),

                      // ── Pick clock format ──────────────
                      SettingsRow(
                        icon:    Icons.access_time_rounded,
                        label:   'Pick clock format',
                        onTap:   () => context
                            .read<SettingsBloc>()
                            .add(const ClockFormatToggled()),
                        trailing: state is SettingsLoaded
                            ? Text(
                                state.is12HourFormat ? '12h' : '24h',
                                style: AppTextStyles.bodySmall,
                              )
                            : null,
                      ),

                      const SizedBox(height: AppDimensions.spaceLg),

                      // ── Pick time delay ────────────────
                      SettingsRow(
                        icon:    Icons.more_time_rounded,
                        label:   'Pick time delay',
                        onTap:   () => _showDelayPicker(context, state),
                        trailing: state is SettingsLoaded
                            ? Text(
                                '+ ${state.alarmDelayMinutes}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.accent,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Delete all logs button ─────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPaddingH,
                  ),
                  child: DeleteLogsButton(
                    onConfirmed: () => context
                        .read<SettingsBloc>()
                        .add(const DeleteAllLogsConfirmed()),
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceMd),

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

  // ── Helpers ───────────────────────────────────────────────

  void _showColorPicker(BuildContext context) {
    // TODO: show a colour picker dialog and dispatch AccentColorChanged
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Pick accent color', style: AppTextStyles.bodyLarge),
        content: Text(
          'Wire up your colour picker here.',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }

  void _showDelayPicker(BuildContext context, SettingsState state) {
    if (state is! SettingsLoaded) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Alarm delay (minutes)', style: AppTextStyles.bodyLarge),
        content: Wrap(
          spacing: 8,
          children: [5, 10, 15, 30].map((mins) {
            return ActionChip(
              label: Text('+$mins', style: AppTextStyles.chipButton),
              backgroundColor: AppColors.accentDim,
              onPressed: () {
                context
                    .read<SettingsBloc>()
                    .add(TimeDelayChanged(mins));
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Settings header ───────────────────────────────────────────
class _SettingsHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _SettingsHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical:   AppDimensions.screenPaddingV,
      ),
      child: Row(
        children: [
          // ── Back arrow ──────────────────────────────────
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded, // ← swap icon
              color:           AppColors.accent,
              size:            22,
              semanticLabel:   'Back',
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMd),

          // ── Title ────────────────────────────────────────
          Text('Settings', style: AppTextStyles.screenTitle),
        ],
      ),
    );
  }
}

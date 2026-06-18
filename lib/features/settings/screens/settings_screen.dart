import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/notification_service.dart';
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
        final accentColor = state is SettingsLoaded ? state.accentColor : AppColors.accent;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: back arrow + title ─────────────
                _SettingsHeader(onBack: onBack, accentColor: accentColor),

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
                        icon:    Icons.palette_outlined,
                        label:   'Pick accent Color',
                        accentColor: accentColor,
                        onTap:   () => _showColorPicker(context, state),
                      ),

                      const SizedBox(height: AppDimensions.spaceLg),

                      // ── Pick clock format ──────────────
                      SettingsRow(
                        icon:    Icons.access_time_rounded,
                        label:   'Pick clock format',
                        accentColor: accentColor,
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
                        accentColor: accentColor,
                        onTap:   () => _showDelayPicker(context, state),
                        trailing: state is SettingsLoaded
                            ? Text(
                                '+ ${state.alarmDelayMinutes}m',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: accentColor,
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(height: AppDimensions.spaceLg),

                      // ── Fix Notifications ────────────────
                      SettingsRow(
                        icon:    Icons.notification_important_outlined,
                        label:   'Fix delayed alerts',
                        accentColor: accentColor,
                        onTap:   () => _requestAdvancedPermissions(context),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: accentColor.withOpacity(0.5),
                        ),
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

  void _requestAdvancedPermissions(BuildContext context) async {
    await AwesomeNotifications().requestPermissionToSendNotifications(
      channelKey: NotificationService.alarmChannelKey,
      permissions: [
        NotificationPermission.PreciseAlarms,
        NotificationPermission.CriticalAlert,
        NotificationPermission.OverrideDnD,
      ],
    );
  }

  void _showColorPicker(BuildContext context, SettingsState state) {
    if (state is! SettingsLoaded) return;
    
    final colors = [
      const Color(0xFFC8F000), // Original Lime
      const Color(0xFF00E5FF), // Cyan
      const Color(0xFF7C4DFF), // Purple
      const Color(0xFFFF4081), // Pink
      const Color(0xFFFFAB40), // Orange
      const Color(0xFF69F0AE), // Teal
      const Color(0xFFFF5252), // Red
      const Color(0xFF448AFF), // Blue
      const Color(0xFFFFD740), // Amber
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Pick accent color', style: AppTextStyles.bodyLarge),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: colors.map((color) {
              final isSelected = state.accentColor.value == color.value;
              return GestureDetector(
                onTap: () {
                  context.read<SettingsBloc>().add(AccentColorChanged(color));
                  Navigator.of(dialogContext).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.black26,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected 
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showDelayPicker(BuildContext context, SettingsState state) {
    if (state is! SettingsLoaded) return;
    
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        int tempDelay = state.alarmDelayMinutes;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Alarm delay', style: AppTextStyles.bodyLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tempDelay >= 60 
                      ? "${(tempDelay / 60).floor()}h ${tempDelay % 60}m" 
                      : "$tempDelay minutes",
                    style: AppTextStyles.bodyMedium.copyWith(color: state.accentColor),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempDelay.toDouble(),
                    min: 1,
                    max: 180,
                    divisions: 179,
                    activeColor: state.accentColor,
                    inactiveColor: state.accentColor.withOpacity(0.2),
                    onChanged: (val) {
                      setState(() => tempDelay = val.toInt());
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel', style: AppTextStyles.bodySmall),
                ),
                TextButton(
                  onPressed: () {
                    context.read<SettingsBloc>().add(TimeDelayChanged(tempDelay));
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Set', 
                    style: AppTextStyles.bodySmall.copyWith(color: state.accentColor),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

// ── Settings header ───────────────────────────────────────────
class _SettingsHeader extends StatelessWidget {
  final VoidCallback onBack;
  final Color        accentColor;

  const _SettingsHeader({required this.onBack, required this.accentColor});

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
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color:           accentColor,
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

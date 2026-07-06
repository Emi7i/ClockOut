import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../../logs/bloc/logs_bloc.dart';
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
        final accentColor = state is SettingsLoaded
            ? state.accentColor
            : Theme.of(context).colorScheme.primary;

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
                        .read<LogsBloc>()
                        .add(const LogsDeleteAllRequested()),
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
    await Permission.notification.request();

    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        // This permission can only be granted from system settings on
        // most Android versions — send the user there directly.
        await openAppSettings();
      }
    }
  }

  void _showColorPicker(BuildContext context, SettingsState state) {
    if (state is! SettingsLoaded) return;

    final settingsBloc = context.read<SettingsBloc>();
    Color tempColor = state.accentColor;

    // Always offer a quick way back to the app's original default, even if
    // it's fallen out of (or never entered) the recently-picked history.
    final swatches = [
      ...state.recentColors,
      if (!state.recentColors.any((c) => c.value == AppColors.accent.value))
        AppColors.accent,
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Pick accent color', style: AppTextStyles.bodyLarge),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPicker(
                    pickerColor: tempColor,
                    onColorChanged: (color) => setState(() => tempColor = color),
                    enableAlpha: false,
                    labelTypes: const [ColorLabelType.hex],
                    pickerAreaHeightPercent: 0.7,
                  ),

                  const SizedBox(height: AppDimensions.spaceMd),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Recent', style: AppTextStyles.bodySmall),
                  ),
                  const SizedBox(height: AppDimensions.spaceXs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final recent in swatches)
                        GestureDetector(
                          onTap: () => setState(() => tempColor = recent),
                          child: Container(
                            width:  32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: recent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: recent.value == tempColor.value
                                    ? Colors.white
                                    : Colors.black26,
                                width: recent.value == tempColor.value ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancel', style: AppTextStyles.bodySmall),
              ),
              TextButton(
                onPressed: () {
                  settingsBloc.add(AccentColorChanged(tempColor));
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Save',
                  style: AppTextStyles.bodySmall.copyWith(color: tempColor),
                ),
              ),
            ],
          );
        },
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

part of 'settings_bloc.dart';

sealed class SettingsState {
  const SettingsState();
}

final class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

final class SettingsLoaded extends SettingsState {
  /// Currently selected accent colour.
  final Color accentColor;

  /// true = 12-hour clock, false = 24-hour clock.
  final bool is12HourFormat;

  /// Alarm delay increment in minutes (e.g. 15).
  final int alarmDelayMinutes;

  const SettingsLoaded({
    required this.accentColor,
    required this.is12HourFormat,
    required this.alarmDelayMinutes,
  });

  SettingsLoaded copyWith({
    Color? accentColor,
    bool?  is12HourFormat,
    int?   alarmDelayMinutes,
  }) {
    return SettingsLoaded(
      accentColor:       accentColor       ?? this.accentColor,
      is12HourFormat:    is12HourFormat    ?? this.is12HourFormat,
      alarmDelayMinutes: alarmDelayMinutes ?? this.alarmDelayMinutes,
    );
  }
}

final class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}

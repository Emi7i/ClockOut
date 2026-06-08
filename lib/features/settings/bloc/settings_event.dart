part of 'settings_bloc.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

/// Screen opened – load current settings.
final class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

/// User picked a new accent colour.
final class AccentColorChanged extends SettingsEvent {
  final Color color;
  const AccentColorChanged(this.color);
}

/// User toggled 12h / 24h clock format.
final class ClockFormatToggled extends SettingsEvent {
  const ClockFormatToggled();
}

/// User changed the alarm delay increment (minutes).
final class TimeDelayChanged extends SettingsEvent {
  final int minutes;
  const TimeDelayChanged(this.minutes);
}

/// User confirmed deletion of all logs.
final class DeleteAllLogsConfirmed extends SettingsEvent {
  const DeleteAllLogsConfirmed();
}

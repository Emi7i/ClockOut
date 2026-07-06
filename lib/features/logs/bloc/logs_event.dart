part of 'logs_bloc.dart';

sealed class LogsEvent {
  const LogsEvent();
}

/// Screen opened – fetch logs.
final class LogsStarted extends LogsEvent {
  const LogsStarted();
}

/// User tapped "Delete all Logs".
final class LogsDeleteAllRequested extends LogsEvent {
  const LogsDeleteAllRequested();
}

/// User tapped "Edit" to toggle edit mode on/off.
final class LogsEditModeToggled extends LogsEvent {
  const LogsEditModeToggled();
}

/// User tapped the donut chart to switch between weekly and monthly stats.
final class LogsPeriodToggled extends LogsEvent {
  const LogsPeriodToggled();
}

/// User edited a log's start/end time while in edit mode.
final class LogEntryEdited extends LogsEvent {
  final LogEntry original;
  final DateTime newClockedInTime;
  final DateTime newClockedOutTime;

  const LogEntryEdited({
    required this.original,
    required this.newClockedInTime,
    required this.newClockedOutTime,
  });
}

/// User deleted a single log entry while in edit mode.
final class LogEntryDeleted extends LogsEvent {
  final LogEntry entry;
  const LogEntryDeleted(this.entry);
}

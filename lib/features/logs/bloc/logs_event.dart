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

/// User tapped "change" (week/month toggle).
final class LogsPeriodToggled extends LogsEvent {
  const LogsPeriodToggled();
}

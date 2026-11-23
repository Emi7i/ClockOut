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

/// User tapped the donut chart to switch between weekly and monthly stats.
final class LogsPeriodToggled extends LogsEvent {
  const LogsPeriodToggled();
}

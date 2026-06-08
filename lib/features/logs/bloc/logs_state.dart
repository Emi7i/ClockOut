part of 'logs_bloc.dart';

sealed class LogsState {
  const LogsState();
}

final class LogsLoading extends LogsState {
  const LogsLoading();
}

final class LogsLoaded extends LogsState {
  final List<LogEntry> entries;

  /// Hours worked this period.
  final double hoursWorked;

  /// Target hours for the period (e.g. 40 for a week).
  final double hoursTarget;

  /// Whether we're showing weekly or monthly data.
  final bool isWeeklyView;

  const LogsLoaded({
    required this.entries,
    required this.hoursWorked,
    required this.hoursTarget,
    this.isWeeklyView = true,
  });

  double get progress =>
      (hoursWorked / hoursTarget).clamp(0.0, 1.0);
}

final class LogsError extends LogsState {
  final String message;
  const LogsError(this.message);
}

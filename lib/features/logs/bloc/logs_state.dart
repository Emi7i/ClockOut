part of 'logs_bloc.dart';

sealed class LogsState {
  const LogsState();
}

final class LogsLoading extends LogsState {
  const LogsLoading();
}

final class LogsLoaded extends LogsState {
  final List<LogEntry> entries;

  /// Hours worked this period (week or month, see [isWeeklyView]).
  final double hoursWorked;

  /// Target hours for the period.
  final double hoursTarget;

  /// Whether the donut chart is showing weekly or monthly stats.
  final bool isWeeklyView;

  /// Whether the user is currently in edit mode (tapping a log opens
  /// the start/end time editor).
  final bool isEditMode;

  const LogsLoaded({
    required this.entries,
    required this.hoursWorked,
    required this.hoursTarget,
    this.isWeeklyView = true,
    this.isEditMode = false,
  });

  double get progress =>
      (hoursWorked / hoursTarget).clamp(0.0, 1.0);
}

final class LogsError extends LogsState {
  final String message;
  const LogsError(this.message);
}

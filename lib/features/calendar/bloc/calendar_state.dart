part of 'calendar_bloc.dart';

final class CalendarState {
  /// First day of the month currently shown.
  final DateTime visibleMonth;

  /// Day whose agenda is shown (date-only).
  final DateTime selectedDay;

  /// Logs grouped by date-only day.
  final Map<DateTime, List<LogEntry>> logsByDay;

  final bool isLoading;

  const CalendarState({
    required this.visibleMonth,
    required this.selectedDay,
    this.logsByDay = const {},
    this.isLoading = true,
  });

  List<LogEntry> logsOn(DateTime day) =>
      logsByDay[MonthGrid.dateOnly(day)] ?? const [];

  /// Overall status of a day, based on the summed bonus time of its logs.
  /// `null` when the day has no logs.
  LogStatus? statusOn(DateTime day) {
    final logs = logsOn(day);
    if (logs.isEmpty) return null;
    final total = logs.fold(Duration.zero, (sum, l) => sum + l.bonusTime);
    if (total == Duration.zero) return LogStatus.onTime;
    return total.isNegative ? LogStatus.late : LogStatus.early;
  }

  CalendarState copyWith({
    DateTime? visibleMonth,
    DateTime? selectedDay,
    Map<DateTime, List<LogEntry>>? logsByDay,
    bool? isLoading,
  }) =>
      CalendarState(
        visibleMonth: visibleMonth ?? this.visibleMonth,
        selectedDay: selectedDay ?? this.selectedDay,
        logsByDay: logsByDay ?? this.logsByDay,
        isLoading: isLoading ?? this.isLoading,
      );
}

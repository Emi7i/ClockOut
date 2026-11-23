part of 'calendar_bloc.dart';

final class CalendarState {
  /// First day of the month currently shown.
  final DateTime visibleMonth;

  /// Day whose agenda is shown (date-only).
  final DateTime selectedDay;

  /// The log of each date-only day. There is at most one log per day.
  final Map<DateTime, LogEntry> logByDay;

  final bool isLoading;

  const CalendarState({
    required this.visibleMonth,
    required this.selectedDay,
    this.logByDay = const {},
    this.isLoading = true,
  });

  LogEntry? logOn(DateTime day) => logByDay[MonthGrid.dateOnly(day)];

  /// Banked time across all logs (can be negative).
  Duration get bankBalance => LogEntry.bankBalance(logByDay.values);

  /// Cat illustration for a day, or `null` when it has no log.
  String? catOn(DateTime day) {
    final log = logOn(day);
    return log == null ? null : CatAssets.forLog(log);
  }

  CalendarState copyWith({
    DateTime? visibleMonth,
    DateTime? selectedDay,
    Map<DateTime, LogEntry>? logByDay,
    bool? isLoading,
  }) =>
      CalendarState(
        visibleMonth: visibleMonth ?? this.visibleMonth,
        selectedDay: selectedDay ?? this.selectedDay,
        logByDay: logByDay ?? this.logByDay,
        isLoading: isLoading ?? this.isLoading,
      );
}

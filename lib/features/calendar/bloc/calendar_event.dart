part of 'calendar_bloc.dart';

sealed class CalendarEvent {
  const CalendarEvent();
}

/// Screen opened – fetch logs.
final class CalendarStarted extends CalendarEvent {
  const CalendarStarted();
}

/// User swiped to (or otherwise navigated to) another month.
final class CalendarMonthChanged extends CalendarEvent {
  final DateTime month;
  const CalendarMonthChanged(this.month);
}

/// User tapped a day in the grid.
final class CalendarDaySelected extends CalendarEvent {
  final DateTime day;
  const CalendarDaySelected(this.day);
}

/// User saved new clock-in/out times for a log.
final class CalendarLogEdited extends CalendarEvent {
  final LogEntry original;
  final DateTime clockedIn;
  final DateTime clockedOut;

  const CalendarLogEdited({
    required this.original,
    required this.clockedIn,
    required this.clockedOut,
  });
}

/// User deleted a log.
final class CalendarLogDeleted extends CalendarEvent {
  final LogEntry entry;
  const CalendarLogDeleted(this.entry);
}

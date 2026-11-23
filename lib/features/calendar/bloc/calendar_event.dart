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

/// User added one or more logs from the add/edit popup (several for a
/// vacation range). Days that already have a log are skipped.
final class CalendarLogsAdded extends CalendarEvent {
  final List<LogEntry> entries;
  const CalendarLogsAdded(this.entries);
}

/// User saved changes to an existing log (matched by [entry]'s id). When a
/// vacation was stretched over more days, the extra days come in
/// [additional] and are added in the same step.
final class CalendarLogUpdated extends CalendarEvent {
  final LogEntry entry;
  final List<LogEntry> additional;

  const CalendarLogUpdated(this.entry, {this.additional = const []});
}

/// User deleted a log.
final class CalendarLogDeleted extends CalendarEvent {
  final LogEntry entry;
  const CalendarLogDeleted(this.entry);
}

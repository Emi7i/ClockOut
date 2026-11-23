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

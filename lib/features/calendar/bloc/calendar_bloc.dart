import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/month_grid.dart';
import '../../../domain/entities/log_entry.dart';
import '../../../domain/use_cases/get_logs_use_case.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

/// ─────────────────────────────────────────────────────────────
///  CALENDAR BLOC
///  Loads logs, groups them by day, and tracks the visible month
///  and the selected day.
/// ─────────────────────────────────────────────────────────────
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetLogsUseCase _getLogs;

  CalendarBloc({required GetLogsUseCase getLogs, DateTime? today})
      : _getLogs = getLogs,
        super(_initialState(today ?? DateTime.now())) {
    on<CalendarStarted>(_onStarted);
    on<CalendarMonthChanged>(_onMonthChanged);
    on<CalendarDaySelected>(_onDaySelected);
  }

  static CalendarState _initialState(DateTime now) => CalendarState(
        visibleMonth: DateTime(now.year, now.month),
        selectedDay: MonthGrid.dateOnly(now),
      );

  Future<void> _onStarted(
    CalendarStarted _,
    Emitter<CalendarState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final entries = await _getLogs();
    emit(state.copyWith(logsByDay: _groupByDay(entries), isLoading: false));
  }

  void _onMonthChanged(
    CalendarMonthChanged event,
    Emitter<CalendarState> emit,
  ) {
    emit(state.copyWith(
      visibleMonth: DateTime(event.month.year, event.month.month),
    ));
  }

  void _onDaySelected(
    CalendarDaySelected event,
    Emitter<CalendarState> emit,
  ) {
    emit(state.copyWith(selectedDay: MonthGrid.dateOnly(event.day)));
  }

  static Map<DateTime, List<LogEntry>> _groupByDay(List<LogEntry> entries) {
    final grouped = <DateTime, List<LogEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(MonthGrid.dateOnly(entry.date), () => []).add(entry);
    }
    return grouped;
  }
}

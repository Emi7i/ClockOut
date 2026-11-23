import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/month_grid.dart';
import '../../../domain/entities/log_entry.dart';
import '../../../domain/repositories/log_repository.dart';
import '../../../domain/use_cases/get_logs_use_case.dart';
import '../cat_assets.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

/// ─────────────────────────────────────────────────────────────
///  CALENDAR BLOC
///  Loads logs, indexes them by day, tracks the visible month and the
///  selected day, and edits / deletes logs.
/// ─────────────────────────────────────────────────────────────
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetLogsUseCase _getLogs;
  final LogRepository _repository;

  CalendarBloc({
    required GetLogsUseCase getLogs,
    required LogRepository repository,
    DateTime? today,
  })  : _getLogs = getLogs,
        _repository = repository,
        super(_initialState(today ?? DateTime.now())) {
    on<CalendarStarted>(_onStarted);
    on<CalendarMonthChanged>(_onMonthChanged);
    on<CalendarDaySelected>(_onDaySelected);
    on<CalendarLogEdited>(_onLogEdited);
    on<CalendarLogDeleted>(_onLogDeleted);
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
    await _reload(emit);
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

  Future<void> _onLogEdited(
    CalendarLogEdited event,
    Emitter<CalendarState> emit,
  ) async {
    await _repository.updateLog(event.original.editedWith(
      clockedIn: event.clockedIn,
      clockedOut: event.clockedOut,
      shiftDuration: AppConstants.shiftDuration,
    ));
    await _reload(emit);
  }

  Future<void> _onLogDeleted(
    CalendarLogDeleted event,
    Emitter<CalendarState> emit,
  ) async {
    final id = event.entry.id;
    if (id == null) return;
    await _repository.deleteLog(id);
    await _reload(emit);
  }

  Future<void> _reload(Emitter<CalendarState> emit) async {
    final entries = await _getLogs();
    emit(state.copyWith(logByDay: _indexByDay(entries), isLoading: false));
  }

  static Map<DateTime, LogEntry> _indexByDay(List<LogEntry> entries) => {
        for (final entry in entries) MonthGrid.dateOnly(entry.date): entry,
      };
}

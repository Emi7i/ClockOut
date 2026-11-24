import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/log_entry.dart';
import '../../../domain/use_cases/get_logs_use_case.dart';
import '../../../domain/repositories/log_repository.dart';

part 'logs_event.dart';
part 'logs_state.dart';

/// ─────────────────────────────────────────────────────────────
///  LOGS BLOC
///  Handles log list fetching, deleting all logs, and the
///  weekly/monthly stats toggle. (Adding, editing and deleting single
///  logs happens in the calendar's add/edit widget.)
/// ─────────────────────────────────────────────────────────────
class LogsBloc extends Bloc<LogsEvent, LogsState> {
  final GetLogsUseCase _getLogs;
  final LogRepository _repository;

  static const double _weeklyTarget = 40.0;
  static const double _monthlyTarget = 160.0;

  LogsBloc({
    required GetLogsUseCase getLogs,
    required LogRepository repository,
  })  : _getLogs = getLogs,
        _repository = repository,
        super(const LogsLoading()) {
    on<LogsStarted>(_onStarted);
    on<LogsDeleteAllRequested>(_onDeleteAll);
    on<LogsPeriodToggled>(_onPeriodToggled);
  }

  Future<void> _onStarted(LogsStarted _, Emitter<LogsState> emit) async {
    emit(const LogsLoading());
    try {
      final entries = await _getLogs();
      emit(LogsLoaded(
        entries: entries,
        hoursWorked: _hoursWorkedFor(entries, true),
        hoursTarget: _weeklyTarget,
      ));
    } catch (e) {
      emit(LogsError(e.toString()));
    }
  }

  Future<void> _onDeleteAll(
    LogsDeleteAllRequested _,
    Emitter<LogsState> emit,
  ) async {
    await _repository.deleteAllLogs();
    final isWeeklyView =
        state is LogsLoaded ? (state as LogsLoaded).isWeeklyView : true;
    emit(LogsLoaded(
      entries: const [],
      hoursWorked: 0,
      hoursTarget: isWeeklyView ? _weeklyTarget : _monthlyTarget,
      isWeeklyView: isWeeklyView,
    ));
  }

  void _onPeriodToggled(LogsPeriodToggled _, Emitter<LogsState> emit) {
    if (state case LogsLoaded loaded) {
      final isNowWeekly = !loaded.isWeeklyView;
      emit(LogsLoaded(
        entries: loaded.entries,
        hoursWorked: _hoursWorkedFor(loaded.entries, isNowWeekly),
        hoursTarget: isNowWeekly ? _weeklyTarget : _monthlyTarget,
        isWeeklyView: isNowWeekly,
      ));
    }
  }

  /// Sums worked hours for entries dated within the current calendar
  /// week (Monday through today) or month (1st through today).
  double _hoursWorkedFor(List<LogEntry> entries, bool isWeeklyView) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final periodStart = isWeeklyView
        ? today.subtract(Duration(days: today.weekday - 1))
        : DateTime(now.year, now.month, 1);

    final totalMinutes = entries
        .where((e) => !e.date.isBefore(periodStart))
        .fold<int>(0, (sum, e) => sum + e.duration.inMinutes);

    return totalMinutes / 60.0;
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/log_entry.dart';
import '../../../domain/use_cases/get_logs_use_case.dart';
import '../../../domain/repositories/log_repository.dart';

part 'logs_event.dart';
part 'logs_state.dart';

/// ─────────────────────────────────────────────────────────────
///  LOGS BLOC
///  Handles log list fetching, deletion, and period toggling.
/// ─────────────────────────────────────────────────────────────
class LogsBloc extends Bloc<LogsEvent, LogsState> {
  final GetLogsUseCase  _getLogs;
  final LogRepository   _repository;

  static const double _weeklyTarget  = 40.0;
  static const double _monthlyTarget = 160.0;

  LogsBloc({
    required GetLogsUseCase getLogs,
    required LogRepository repository,
  })  : _getLogs    = getLogs,
        _repository = repository,
        super(const LogsLoading()) {
    on<LogsStarted>           (_onStarted);
    on<LogsDeleteAllRequested>(_onDeleteAll);
    on<LogsPeriodToggled>     (_onPeriodToggled);
  }

  Future<void> _onStarted(LogsStarted _, Emitter<LogsState> emit) async {
    emit(const LogsLoading());
    try {
      final entries = await _getLogs();
      emit(LogsLoaded(
        entries:      entries,
        hoursWorked:  32,            // ← wire to real data
        hoursTarget:  _weeklyTarget,
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
    emit(const LogsLoaded(
      entries:     [],
      hoursWorked: 0,
      hoursTarget: _weeklyTarget,
    ));
  }

  void _onPeriodToggled(LogsPeriodToggled _, Emitter<LogsState> emit) {
    if (state case LogsLoaded loaded) {
      final isNowWeekly = !loaded.isWeeklyView;
      emit(LogsLoaded(
        entries:      loaded.entries,
        hoursWorked:  loaded.hoursWorked,
        hoursTarget:  isNowWeekly ? _weeklyTarget : _monthlyTarget,
        isWeeklyView: isNowWeekly,
      ));
    }
  }
}

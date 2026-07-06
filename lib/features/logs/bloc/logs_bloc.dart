import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/log_entry.dart';
import '../../../domain/use_cases/get_logs_use_case.dart';
import '../../../domain/repositories/log_repository.dart';

part 'logs_event.dart';
part 'logs_state.dart';

/// ─────────────────────────────────────────────────────────────
///  LOGS BLOC
///  Handles log list fetching, deletion, editing, and the
///  weekly/monthly stats toggle.
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
    on<LogsEditModeToggled>   (_onEditModeToggled);
    on<LogsPeriodToggled>     (_onPeriodToggled);
    on<LogEntryEdited>        (_onEntryEdited);
    on<LogEntryDeleted>       (_onEntryDeleted);
  }

  Future<void> _onStarted(LogsStarted _, Emitter<LogsState> emit) async {
    emit(const LogsLoading());
    try {
      final entries = await _getLogs();
      emit(LogsLoaded(
        entries:      entries,
        hoursWorked:  _hoursWorkedFor(entries, true),
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
    final isWeeklyView = state is LogsLoaded ? (state as LogsLoaded).isWeeklyView : true;
    emit(LogsLoaded(
      entries:      const [],
      hoursWorked:  0,
      hoursTarget:  isWeeklyView ? _weeklyTarget : _monthlyTarget,
      isWeeklyView: isWeeklyView,
    ));
  }

  void _onEditModeToggled(LogsEditModeToggled _, Emitter<LogsState> emit) {
    if (state case LogsLoaded loaded) {
      emit(LogsLoaded(
        entries:      loaded.entries,
        hoursWorked:  loaded.hoursWorked,
        hoursTarget:  loaded.hoursTarget,
        isWeeklyView: loaded.isWeeklyView,
        isEditMode:   !loaded.isEditMode,
      ));
    }
  }

  void _onPeriodToggled(LogsPeriodToggled _, Emitter<LogsState> emit) {
    if (state case LogsLoaded loaded) {
      final isNowWeekly = !loaded.isWeeklyView;
      emit(LogsLoaded(
        entries:      loaded.entries,
        hoursWorked:  _hoursWorkedFor(loaded.entries, isNowWeekly),
        hoursTarget:  isNowWeekly ? _weeklyTarget : _monthlyTarget,
        isWeeklyView: isNowWeekly,
        isEditMode:   loaded.isEditMode,
      ));
    }
  }

  Future<void> _onEntryEdited(
    LogEntryEdited event,
    Emitter<LogsState> emit,
  ) async {
    final bonusTime = LogEntry.computeBonusTime(
      clockedInAt:  event.newClockedInTime,
      clockedOutAt: event.newClockedOutTime,
      shiftDuration: AppConstants.shiftDuration,
    );

    final updated = LogEntry(
      id:             event.original.id,
      date:           event.newClockedInTime,
      bonusTime:      bonusTime,
      userEdited:     true,
      clockedInTime:  event.newClockedInTime,
      clockedOutTime: event.newClockedOutTime,
      onlineWork:     event.original.onlineWork,
    );
    await _repository.updateLog(updated);

    final entries = await _getLogs();
    if (state case LogsLoaded loaded) {
      emit(LogsLoaded(
        entries:      entries,
        hoursWorked:  _hoursWorkedFor(entries, loaded.isWeeklyView),
        hoursTarget:  loaded.hoursTarget,
        isWeeklyView: loaded.isWeeklyView,
        isEditMode:   loaded.isEditMode,
      ));
    }
  }

  Future<void> _onEntryDeleted(
    LogEntryDeleted event,
    Emitter<LogsState> emit,
  ) async {
    if (event.entry.id == null) return;
    await _repository.deleteLog(event.entry.id!);

    final entries = await _getLogs();
    if (state case LogsLoaded loaded) {
      emit(LogsLoaded(
        entries:      entries,
        hoursWorked:  _hoursWorkedFor(entries, loaded.isWeeklyView),
        hoursTarget:  loaded.hoursTarget,
        isWeeklyView: loaded.isWeeklyView,
        isEditMode:   loaded.isEditMode,
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

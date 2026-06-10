import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/clock_in_use_case.dart';
import '../../../domain/use_cases/clock_out_use_case.dart';
import '../../../domain/repositories/clock_repository.dart';
import '../../../core/services/notification_service.dart';

part 'clock_event.dart';
part 'clock_state.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK BLOC
///  Orchestrates Clock In / Clocked In screen logic.
///  Emits a [ClockTicked] every second while clocked in so the
///  countdown and time display stay live.
/// ─────────────────────────────────────────────────────────────
class ClockBloc extends Bloc<ClockEvent, ClockState> {
  final ClockInUseCase  _clockIn;
  final ClockOutUseCase _clockOut;
  final ClockRepository _repository;
  final NotificationService _notificationService;

  /// Length of a full work shift – set to 30 sec for testing.
  // static const Duration _shiftDuration = Duration(seconds: 30);

  static const Duration _shiftDuration = Duration(hours: 8);

  Timer? _ticker;

  ClockBloc({
    required ClockInUseCase clockIn,
    required ClockOutUseCase clockOut,
    required ClockRepository repository,
    required NotificationService notificationService,
  })  : _clockIn    = clockIn,
        _clockOut   = clockOut,
        _repository = repository,
        _notificationService = notificationService,
        super(const ClockLoading()) {
    on<ClockStarted>    (_onStarted);
    on<ClockInRequested>(_onClockIn);
    on<ClockOutRequested>(_onClockOut);
    on<AlarmToggled>    (_onAlarmToggled);
    on<ClockTicked>     (_onTicked);
  }

  // ── Handlers ──────────────────────────────────────────────

  Future<void> _onStarted(ClockStarted _, Emitter<ClockState> emit) async {
    try {
      final active = await _repository.getActiveEntry();
      if (active == null) {
        emit(ClockIdle(currentTime: DateTime.now()));
      } else {
        _startTicker();
        final state = _buildActiveState(active.clockedInAt, active.alarmEnabled);
        emit(state);

        // Re-schedule notification if active session exists
        final endOfShift = active.clockedInAt.add(_shiftDuration);
        if (endOfShift.isAfter(DateTime.now())) {
          _notificationService.scheduleShiftEndNotification(
            scheduledDate: endOfShift,
            withAlarm: active.alarmEnabled,
          );
        }
      }
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onClockIn(
    ClockInRequested _,
    Emitter<ClockState> emit,
  ) async {
    try {
      final entry = await _clockIn();
      _startTicker();
      final state = _buildActiveState(entry.clockedInAt, entry.alarmEnabled);
      emit(state);

      // Schedule notification for the end of the shift
      _notificationService.scheduleShiftEndNotification(
        scheduledDate: entry.clockedInAt.add(_shiftDuration),
        withAlarm: entry.alarmEnabled,
      );
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onClockOut(
    ClockOutRequested _,
    Emitter<ClockState> emit,
  ) async {
    try {
      _ticker?.cancel();
      await _clockOut();
      emit(ClockIdle(currentTime: DateTime.now()));

      // Cancel the scheduled notification
      _notificationService.cancelAllShiftNotifications();
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onAlarmToggled(
    AlarmToggled event,
    Emitter<ClockState> emit,
  ) async {
    await _repository.setAlarm(enabled: event.enabled);
    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, event.enabled));

      // Update the scheduled notification to include/remove alarm sound
      _notificationService.scheduleShiftEndNotification(
        scheduledDate: active.clockedInAt.add(_shiftDuration),
        withAlarm: event.enabled,
      );
    } else if (state case ClockIdle idle) {
      emit(ClockIdle(
        currentTime:  idle.currentTime,
        alarmEnabled: event.enabled,
      ));
    }
  }

  void _onTicked(ClockTicked _, Emitter<ClockState> emit) {
    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  ClockActive _buildActiveState(DateTime clockedInAt, bool alarmEnabled) {
    final now       = DateTime.now();
    final elapsed   = now.difference(clockedInAt);
    final remaining = _shiftDuration - elapsed;

    return ClockActive(
      currentTime:  now,
      clockedInAt:  clockedInAt,
      remaining:    remaining.isNegative ? Duration.zero : remaining,
      alarmEnabled: alarmEnabled,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const ClockTicked()),
    );
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}

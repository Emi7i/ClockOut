import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm/model/notification_settings.dart';
import 'package:alarm/model/volume_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/clock_in_use_case.dart';
import '../../../domain/use_cases/clock_out_use_case.dart';
import '../../../domain/repositories/active_session_repository.dart';
import '../../../domain/repositories/user_settings_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/alarm_service.dart';
import 'dart:developer' as developer;

part 'clock_event.dart';
part 'clock_state.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK BLOC
///  Orchestrates Clock In / Clocked In screen logic.
///  Emits a [ClockTicked] every second while clocked in so the
///  countdown and time display stay live.
///
///  Alarm IDs:
///    1 → shift-end alarm (scheduled at clock-in)
///    2 → repeat alarm    (rescheduled every 30 min after shift end)
/// ─────────────────────────────────────────────────────────────
class ClockBloc extends Bloc<ClockEvent, ClockState> {
  final ClockInUseCase              _clockIn;
  final ClockOutUseCase             _clockOut;
  final ActiveSessionRepository     _repository;
  final UserSettingsRepository      _settingsRepository;
  final NotificationService         _notificationService;
  final AlarmService                _alarmService;
  static const Duration _shiftDuration = Duration(minutes: 1);

  static const int _shiftAlarmId  = 1;
  static const int _repeatAlarmId = 2;

  Timer?            _ticker;
  StreamSubscription<AlarmSettings>? _alarmRingSubscription;
  DateTime?         _nextAlarmAt;
  bool              _isRinging = false;

  ClockBloc({
    required ClockInUseCase clockIn,
    required ClockOutUseCase clockOut,
    required ActiveSessionRepository repository,
    required UserSettingsRepository settingsRepository,
    required NotificationService notificationService,
    required AlarmService alarmService,
  })  : _clockIn             = clockIn,
        _clockOut            = clockOut,
        _repository          = repository,
        _settingsRepository  = settingsRepository,
        _notificationService = notificationService,
        _alarmService        = alarmService,
        super(const ClockLoading()) {
    on<ClockStarted>      (_onStarted);
    on<ClockInRequested>  (_onClockIn);
    on<ClockInTimeEdited> (_onClockInTimeEdited);
    on<ClockOutRequested> (_onClockOut);
    on<AlarmToggled>      (_onAlarmToggled);
    on<AlarmStopRequested>(_onAlarmStop);
    on<AlertFired>        (_onAlertFired);
    on<ClockTicked>       (_onTicked);

    _listenToAlarmRings();
  }

  // ── Alarm ring listener ───────────────────────────────────
  void _listenToAlarmRings() {
    _alarmRingSubscription = _alarmService.ringStream.listen((alarmSettings) {
      if (alarmSettings.id == _shiftAlarmId ||
          alarmSettings.id == _repeatAlarmId) {
        add(AlertFired((alarmSettings.id == _shiftAlarmId) ? false : true));
      }
    });
  }

  Future<void> _onAlertFired(
      AlertFired _,
      Emitter<ClockState> emit,
      {isRepeatingAlarm}
      ) async {
    if (state case ClockActive active) {
      if (active.alarmEnabled) {
        _isRinging = true;
      }
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
      isRepeatingAlarm ? await _scheduleRepeatAlarm() : await _scheduleShiftAlarm()
        ;

    }
  }

  // ── Handlers ──────────────────────────────────────────────

  Future<void> _onStarted(
      ClockStarted _,
      Emitter<ClockState> emit,
      ) async {
    try {
      final active = await _repository.getActiveSession();
      if (active == null) {
        emit(ClockIdle(currentTime: DateTime.now()));
      } else {
        _startTicker();

        final settings = await _settingsRepository.getSettings();
        final endOfShift = active.clockedInAt.add(_shiftDuration);
        
        if (endOfShift.isAfter(DateTime.now())) {
          _nextAlarmAt = endOfShift;
          
          _notificationService.scheduleShiftEndNotification(
            scheduledDate: endOfShift,
            delayMinutes:  settings.alarmDelayMinutes,
            alarmEnabled:  active.alarmEnabled,
          );
        } else {
          await _scheduleRepeatAlarm(immediately: true);
        }

        emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
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
      final bool initialAlarmEnabled = state is ClockIdle ? (state as ClockIdle).alarmEnabled : false;

      final session = await _clockIn();
      _startTicker();

      final settings = await _settingsRepository.getSettings();
      final endOfShift = session.clockedInAt.add(_shiftDuration);
      _nextAlarmAt = endOfShift;
      
      _notificationService.scheduleShiftEndNotification(
        scheduledDate: endOfShift,
        delayMinutes:  settings.alarmDelayMinutes,
        alarmEnabled:  initialAlarmEnabled,
      );

      emit(_buildActiveState(session.clockedInAt, initialAlarmEnabled));
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onClockInTimeEdited(
      ClockInTimeEdited event,
      Emitter<ClockState> emit,
      ) async {
    if (state is! ClockActive) return;
    
    try {
      final activeState = state as ClockActive;
      
      await _repository.updateActiveClockInTime(event.newTime);
      
      final settings = await _settingsRepository.getSettings();
      final endOfShift = event.newTime.add(_shiftDuration);
      
      await _cancelAllAlarms();
      
      _nextAlarmAt = endOfShift;

      _notificationService.scheduleShiftEndNotification(
        scheduledDate: endOfShift,
        delayMinutes:  settings.alarmDelayMinutes,
        alarmEnabled:  activeState.alarmEnabled,
      );

      emit(_buildActiveState(event.newTime, activeState.alarmEnabled));
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
      await _cancelAllAlarms();
      _nextAlarmAt = null;
      _isRinging = false;
      await _clockOut();
      _notificationService.cancelAllShiftNotifications();
      emit(ClockIdle(currentTime: DateTime.now()));
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onAlarmStop(
    AlarmStopRequested _,
    Emitter<ClockState> emit,
  ) async {
    await _alarmService.stop(_shiftAlarmId);
    await _alarmService.stop(_repeatAlarmId);
    _isRinging = false;
    
    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  Future<void> _onAlarmToggled(
      AlarmToggled event,
      Emitter<ClockState> emit,
      ) async {
    await _repository.setAlarm(enabled: event.enabled);

    if (state case ClockActive active) {
      final settings = await _settingsRepository.getSettings();
      final endOfShift = active.clockedInAt.add(_shiftDuration);

      if (endOfShift.isAfter(DateTime.now())) {
        _notificationService.scheduleShiftEndNotification(
          scheduledDate: endOfShift,
          delayMinutes:  settings.alarmDelayMinutes,
          alarmEnabled:  event.enabled,
        );
      } else {
        if (_nextAlarmAt != null) {
          await _scheduleRepeatAlarm(at: _nextAlarmAt);
        }
      }
      
      emit(_buildActiveState(active.clockedInAt, event.enabled));
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

  // ── Alarm helpers ─────────────────────────────────────────

  Future<void> _scheduleShiftAlarm() async {
    _nextAlarmAt = DateTime.now().add(const Duration(hours: 8));

    final bool alarmEnabled = state is ClockActive ?
    (state as ClockActive).alarmEnabled : true;

    final settings = await _settingsRepository.getSettings();

    await _notificationService.scheduleShiftEndNotification(
      scheduledDate: _nextAlarmAt ??= DateTime.now(),
      delayMinutes:  settings.alarmDelayMinutes,
      alarmEnabled:  alarmEnabled,
    );
  }

  Future<void> _scheduleRepeatAlarm({bool immediately = false, DateTime? at}) async {
    await _alarmService.stop(_repeatAlarmId);

    final settings = await _settingsRepository.getSettings();
    final interval = Duration(minutes: settings.alarmDelayMinutes);

    final DateTime fireAt = immediately ? DateTime.now() : DateTime.now().add(interval);

    _nextAlarmAt =  at ?? fireAt;

    developer.log("_nextAlarmAt = $_nextAlarmAt");

    final activeSession = await _repository.getActiveSession();
    final bool alarmEnabled = activeSession?.alarmEnabled ?? false;

    await _notificationService.scheduleRepeatNotification(
      scheduledDate: _nextAlarmAt ??= DateTime.now(),
      delayMinutes:  settings.alarmDelayMinutes,
      alarmEnabled:  alarmEnabled,
    );
  }

  Future<void> _cancelAllAlarms() async {
    await _alarmService.stop(_shiftAlarmId);
    await _alarmService.stop(_repeatAlarmId);
  }

  // ── Helpers ───────────────────────────────────────────────

  ClockActive _buildActiveState(DateTime clockedInAt, bool alarmEnabled) {
    final now      = DateTime.now();
    final elapsed  = now.difference(clockedInAt);
    final remaining = _shiftDuration - elapsed;

    Duration? nextAlarmIn;
    if (_nextAlarmAt != null) {
      nextAlarmIn = _nextAlarmAt!.difference(now);
      if (nextAlarmIn.isNegative) nextAlarmIn = Duration.zero;
    }

    return ClockActive(
      currentTime:  now,
      clockedInAt:  clockedInAt,
      remaining:    remaining.isNegative ? Duration.zero : remaining,
      alarmEnabled: alarmEnabled,
      nextAlarmIn:  nextAlarmIn,
      isRinging:    _isRinging,
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
    _alarmRingSubscription?.cancel();
    return super.close();
  }
}

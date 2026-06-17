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
import '../../../domain/repositories/clock_repository.dart';
import '../../../domain/repositories/user_settings_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/alarm_service.dart';

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
  final ClockInUseCase          _clockIn;
  final ClockOutUseCase         _clockOut;
  final ClockRepository         _repository;
  final UserSettingsRepository  _settingsRepository;
  final NotificationService     _notificationService;
  final AlarmService            _alarmService;

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
    required ClockRepository repository,
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
  // Alarm.onAlarmRinging fires when an alarm goes off while the app
  // is in the foreground. We stop it immediately — the alarm package
  // shows its own UI; our job here is just to schedule the next repeat.
  void _listenToAlarmRings() {
    _alarmRingSubscription = _alarmService.ringStream.listen((alarmSettings) {
      if (alarmSettings.id == _shiftAlarmId ||
          alarmSettings.id == _repeatAlarmId) {
        add(const AlertFired());
      }
    });
  }

  Future<void> _onAlertFired(
      AlertFired _,
      Emitter<ClockState> emit,
      ) async {
    if (state case ClockActive active) {
      if (active.alarmEnabled) {
        _isRinging = true;
      }
      // ALWAYS schedule the next repeat, regardless of sound setting
      await _scheduleRepeatAlarm();
      
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  // ── Handlers ──────────────────────────────────────────────

  Future<void> _onStarted(
      ClockStarted _,
      Emitter<ClockState> emit,
      ) async {
    try {
      final active = await _repository.getActiveEntry();
      if (active == null) {
        emit(ClockIdle(currentTime: DateTime.now()));
      } else {
        _startTicker();

        final settings = await _settingsRepository.getSettings();
        final endOfShift = active.clockedInAt.add(_shiftDuration);
        
        if (endOfShift.isAfter(DateTime.now())) {
          _nextAlarmAt = endOfShift; // Track for countdown and continuous background logic
          
          // Shift hasn't ended yet — (re)schedule both notification & alarm.
          _notificationService.scheduleShiftEndNotification(
            scheduledDate: endOfShift,
            delayMinutes:  settings.alarmDelayMinutes,
            alarmEnabled:  active.alarmEnabled,
          );
          if (active.alarmEnabled) {
            await _scheduleShiftAlarm(endOfShift);
          }
        } else {
          // Shift already ended — fire a repeat immediately to catch up
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
      // Preserve the alarm toggle from the current idle state
      final bool initialAlarmEnabled = state is ClockIdle ? (state as ClockIdle).alarmEnabled : false;

      final entry = await _clockIn();
      _startTicker();

      final settings = await _settingsRepository.getSettings();
      final endOfShift = entry.clockedInAt.add(_shiftDuration);
      _nextAlarmAt = endOfShift; // Track for countdown and continuous background logic
      
      // Always schedule notification, but alarmEnabled controls the sound/hardware alarm
      _notificationService.scheduleShiftEndNotification(
        scheduledDate: endOfShift,
        delayMinutes:  settings.alarmDelayMinutes,
        alarmEnabled:  initialAlarmEnabled,
      );

      if (initialAlarmEnabled) {
        await _scheduleShiftAlarm(endOfShift);
      }

      emit(_buildActiveState(entry.clockedInAt, initialAlarmEnabled));
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
      
      // 1. Update the database
      await _repository.updateActiveClockInTime(event.newTime);
      
      // 2. Reschedule alarms and notifications based on the new time
      final settings = await _settingsRepository.getSettings();
      final endOfShift = event.newTime.add(_shiftDuration);
      
      // Cancel existing ones first just in case
      await _cancelAllAlarms();
      
      _nextAlarmAt = endOfShift; // Track for countdown and continuous background logic

      _notificationService.scheduleShiftEndNotification(
        scheduledDate: endOfShift,
        delayMinutes:  settings.alarmDelayMinutes,
        alarmEnabled:  activeState.alarmEnabled,
      );

      if (endOfShift.isAfter(DateTime.now())) {
        if (activeState.alarmEnabled) {
          await _scheduleShiftAlarm(endOfShift);
        }
      } else {
        await _scheduleRepeatAlarm(immediately: true);
      }

      // 3. Emit new state
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
    // Stop whatever is ringing now.
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

      // Always reschedule the notification (it reflects alarm toggle too).
      _notificationService.scheduleShiftEndNotification(
        scheduledDate: endOfShift,
        delayMinutes:  settings.alarmDelayMinutes,
        alarmEnabled:  event.enabled,
      );

      if (event.enabled) {
        // Sound turned ON.
        if (endOfShift.isAfter(DateTime.now())) {
          await _scheduleShiftAlarm(endOfShift);
        } else if (_nextAlarmAt != null) {
          // If we already have a repeat scheduled, set the hardware alarm for it
          await _scheduleRepeatAlarm(at: _nextAlarmAt);
        }
      } else {
        // Sound turned OFF — cancel hardware alarms but KEEP countdown/repeats.
        await _cancelAllAlarms();
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
    if (_nextAlarmAt != null && DateTime.now().isAfter(_nextAlarmAt!)) {
      // Prevent double firing before the alert gets processed and reschedules
      _nextAlarmAt = null;
      add(const AlertFired());
    }

    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  // ── Alarm helpers ─────────────────────────────────────────

  /// Schedules the first alarm that fires at the end of the shift.
  Future<void> _scheduleShiftAlarm(DateTime dateTime) async {
    _nextAlarmAt = dateTime;
    await _alarmService.setAlarm(
      id:       _shiftAlarmId,
      dateTime: dateTime,
      title:    'Shift Over!',
      body:     'Your shift has ended. Time to clock out!',
    );
  }

  /// Schedules the repeating alarm (delay taken from UserSettings)
  /// from now (or immediately with a 1-second offset if [immediately] is true).
  /// If [at] is provided, schedules it at that exact time.
  Future<void> _scheduleRepeatAlarm({bool immediately = false, DateTime? at}) async {
    // Cancel the previous repeat before scheduling a new one.
    await _alarmService.stop(_repeatAlarmId);

    final settings = await _settingsRepository.getSettings();
    final interval = Duration(minutes: settings.alarmDelayMinutes);

    final DateTime fireAt = at ?? (immediately
        ? DateTime.now().add(const Duration(seconds: 1))
        : DateTime.now().add(interval));

    _nextAlarmAt = fireAt;

    // Only set the hardware alarm if the toggle is ON
    if (state case ClockActive active when active.alarmEnabled) {
      await _alarmService.setAlarm(
        id:       _repeatAlarmId,
        dateTime: fireAt,
        title:    'Still not clocked out!',
        body:     'Your shift ended a while ago. Please clock out.',
      );
    }

    // ALWAYS schedule notification repeat, payload carries the sound preference
    await _notificationService.scheduleRepeatNotification(
      scheduledDate: fireAt,
      delayMinutes:  settings.alarmDelayMinutes,
      alarmEnabled:  state is ClockActive ? (state as ClockActive).alarmEnabled : true,
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
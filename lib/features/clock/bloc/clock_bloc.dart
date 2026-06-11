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

  static const Duration _shiftDuration = Duration(hours: 8);

  static const int _shiftAlarmId  = 1;
  static const int _repeatAlarmId = 2;

  Timer?            _ticker;
  StreamSubscription<AlarmSettings>? _alarmRingSubscription;

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
    on<ClockOutRequested> (_onClockOut);
    on<AlarmToggled>      (_onAlarmToggled);
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
        _onAlarmFired(alarmSettings.id);
      }
    });
  }

  /// Called when either alarm fires (foreground) OR when the user
  /// dismisses the alarm notification (via NotificationController callback
  /// in notification_service.dart for background/killed scenarios).
  ///
  /// Exposed as a static entry point so notification_service.dart can call it.
  void _onAlarmFired(int alarmId) {
    if (state case ClockActive active when active.alarmEnabled) {
      _scheduleRepeatAlarm();
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
        emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));

        final endOfShift = active.clockedInAt.add(_shiftDuration);
        if (endOfShift.isAfter(DateTime.now())) {
          // Shift hasn't ended yet — (re)schedule both notification & alarm.
          _notificationService.scheduleShiftEndNotification(
            scheduledDate: endOfShift,
          );
          if (active.alarmEnabled) {
            await _scheduleShiftAlarm(endOfShift);
          }
        } else if (active.alarmEnabled) {
          // Shift already ended while app was closed — fire a repeat
          // immediately so the user isn't silently left clocked in.
          await _scheduleRepeatAlarm(immediately: true);
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
      emit(_buildActiveState(entry.clockedInAt, entry.alarmEnabled));

      final endOfShift = entry.clockedInAt.add(_shiftDuration);
      _notificationService.scheduleShiftEndNotification(
        scheduledDate: endOfShift,
      );
      if (entry.alarmEnabled) {
        await _scheduleShiftAlarm(endOfShift);
      }
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
      await _clockOut();
      _notificationService.cancelAllShiftNotifications();
      emit(ClockIdle(currentTime: DateTime.now()));
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

      final endOfShift = active.clockedInAt.add(_shiftDuration);

      // Always reschedule the notification (it reflects alarm toggle too).
      _notificationService.scheduleShiftEndNotification(
        scheduledDate: endOfShift,
      );

      if (event.enabled) {
        // Alarm turned ON.
        if (endOfShift.isAfter(DateTime.now())) {
          await _scheduleShiftAlarm(endOfShift);
        } else {
          // Shift already over — start repeat cycle immediately.
          await _scheduleRepeatAlarm(immediately: true);
        }
      } else {
        // Alarm turned OFF — cancel any pending alarms.
        await _cancelAllAlarms();
      }
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

  /// Schedules the first alarm that fires at the end of the shift.
  Future<void> _scheduleShiftAlarm(DateTime dateTime) async {
    await _alarmService.setAlarm(
      id:       _shiftAlarmId,
      dateTime: dateTime,
      title:    'Shift Over!',
      body:     'Your shift has ended. Time to clock out!',
    );
  }

  /// Schedules the repeating alarm (delay taken from UserSettings)
  /// from now (or immediately with a 1-second offset if [immediately] is true).
  Future<void> _scheduleRepeatAlarm({bool immediately = false}) async {
    // Cancel the previous repeat before scheduling a new one.
    await _alarmService.stop(_repeatAlarmId);

    final settings = await _settingsRepository.getSettings();
    final interval = Duration(minutes: settings.alarmDelayMinutes);

    final DateTime fireAt = immediately
        ? DateTime.now().add(const Duration(seconds: 1))
        : DateTime.now().add(interval);

    await _alarmService.setAlarm(
      id:       _repeatAlarmId,
      dateTime: fireAt,
      title:    'Still not clocked out!',
      body:     'Your shift ended a while ago. Please clock out.',
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
    _alarmRingSubscription?.cancel();
    return super.close();
  }
}
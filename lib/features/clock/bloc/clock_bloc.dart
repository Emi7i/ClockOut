import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/clock_in_use_case.dart';
import '../../../domain/use_cases/clock_out_use_case.dart';
import '../../../domain/repositories/active_session_repository.dart';
import '../../../domain/repositories/user_settings_repository.dart';
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
  final ClockInUseCase              _clockIn;
  final ClockOutUseCase             _clockOut;
  final ActiveSessionRepository     _repository;
  final UserSettingsRepository      _settingsRepository;
  final NotificationService         _notificationService;

  // Debug
  static const Duration _shiftDuration = Duration(seconds: 30);
  //static const Duration _shiftDuration = Duration(hours: 8);

  Timer?              _ticker;
  StreamSubscription? _alertFiredSubscription;
  DateTime?           _nextAlarmAt;
  bool                _isRinging = false;
  int                 _currentNotificationId = NotificationService.shiftAlarmId;

  ClockBloc({
    required ClockInUseCase clockIn,
    required ClockOutUseCase clockOut,
    required ActiveSessionRepository repository,
    required UserSettingsRepository settingsRepository,
    required NotificationService notificationService,
  })  : _clockIn             = clockIn,
        _clockOut            = clockOut,
        _repository          = repository,
        _settingsRepository  = settingsRepository,
        _notificationService = notificationService,
        super(const ClockLoading()) {
    on<ClockStarted>      (_onStarted);
    on<ClockInRequested>  (_onClockIn);
    on<ClockInTimeEdited> (_onClockInTimeEdited);
    on<ClockOutRequested> (_onClockOut);
    on<AlarmToggled>      (_onAlarmToggled);
    on<AlarmStopRequested>(_onAlarmStop);
    on<AlertFired>        (_onAlertFired);
    on<ClockTicked>       (_onTicked);

    _listenToAlertFired();
  }

  void _listenToAlertFired() {
    _alertFiredSubscription = _notificationService.alertFiredStream.listen((id) {
      if (NotificationService.allIds.contains(id)) {
        add(AlertFired(id));
      }
    });
  }

  // ── Handlers ──────────────────────────────────────────────

  Future<void> _onStarted(
      ClockStarted event,
      Emitter<ClockState> emit,
      ) async {
    try {
      final active = await _repository.getActiveSession();
      if (active == null) {
        emit(ClockIdle(currentTime: DateTime.now()));
      } else {
        _startTicker();

        // Recover ringing state in case the app was killed/backgrounded
        // while an alert was firing.
        final ringingId = await _notificationService.currentlyRingingId();
        if (ringingId != null) {
          _currentNotificationId = ringingId;
          _isRinging = true;
        }

        emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
      }
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onClockIn(
      ClockInRequested event,
      Emitter<ClockState> emit,
      ) async {
    try {
      final bool initialAlarmEnabled = state is ClockIdle ? (state as ClockIdle).alarmEnabled : false;
      final session = await _clockIn();
      _startTicker();

      scheduleNextAlarm();

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

      await _notificationService.cancelAllShiftNotifications();
      scheduleNextAlarm();

      emit(_buildActiveState(event.newTime, activeState.alarmEnabled));
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onClockOut(
      ClockOutRequested event,
      Emitter<ClockState> emit,
      ) async {
    try {
      _ticker?.cancel();
      await _notificationService.cancelAllShiftNotifications();

      _nextAlarmAt             = null;
      _isRinging               = false;
      await _clockOut();

      emit(ClockIdle(currentTime: DateTime.now()));
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onAlarmStop(AlarmStopRequested event, Emitter<ClockState> emit) async {
    stopActiveAlarm();
    _isRinging = false;
    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  Future<void> _onAlarmToggled(
      AlarmToggled event,
      Emitter<ClockState> emit,
      ) async {
    await _repository.setAlarmSound(enabled: event.enabled);
    // cancel the current notif gracefully
    stopActiveAlarm();

    if (state case ClockActive active) {
      scheduleNextAlarm(override: true); // overrides current notif
      emit(_buildActiveState(active.clockedInAt, event.enabled));
    } else if (state case ClockIdle idle) {
      emit(ClockIdle(
        currentTime:  idle.currentTime,
        alarmEnabled: event.enabled,
      ));
    }
  }

  Future<void> _onAlertFired(AlertFired event, Emitter<ClockState> emit) async {
    // Sync to the id that actually just rang — don't trust whatever was
    // last set on a manual stop, since the user may have missed dismissing
    // one or more repeats in between.
    //
    // Note: we deliberately don't cancel other pool ids here. Calling
    // Alarm.stop() on an unrelated id reaches into the same native alarm
    // service that's ringing the real alert, and on a cold start (e.g. the
    // screen was locked and the full-screen intent just relaunched the app)
    // that races with the media player spinning up and can tear the whole
    // service down a second in, killing the real alarm's vibration/sound.
    // allowAlarmOverlap on AlarmService already guarantees the newest alert
    // rings regardless of a stale previous one.
    _currentNotificationId = event.id;

    if (state case ClockActive active) {
      if (active.alarmEnabled) {
        _isRinging = true;
      }
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
    scheduleNextAlarm();
  }

  void _onTicked(ClockTicked event, Emitter<ClockState> emit) {
    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  /// This function schedules the next alarm automatically
  void scheduleNextAlarm({bool override = false}) async{
    try {
      final active = await _repository.getActiveSession();
      final settings = await _settingsRepository.getSettings();
      final endOfShift = active?.clockedInAt.add(_shiftDuration);

      // If shift hasn't ended yet, schedule a shift end alarm
      // We need a buffer of 2 seconds to avoid race condition
      if (endOfShift!.isAfter(DateTime.now().add(const Duration(seconds: 2)))) {
        await _notificationService.scheduleShiftEndNotification(
          scheduledDate: endOfShift,
          delayMinutes: settings.alarmDelayMinutes,
          alarmEnabled: active!.alarmEnabled,
        );
      } else {
        final delay = Duration(minutes: settings.alarmDelayMinutes);
        DateTime nextRepeat = endOfShift.add(delay);

        while (nextRepeat.isBefore(DateTime.now())) {
          nextRepeat = nextRepeat.add(delay);
        }

        _nextAlarmAt = nextRepeat;
        var notifToSchedule = override ? _currentNotificationId : _getNextRepeatId();

        await _notificationService.scheduleRepeatNotification(
          scheduledDate: nextRepeat,
          delayMinutes: settings.alarmDelayMinutes,
          alarmEnabled: active!.alarmEnabled,
          // Alarm toggle needs to override current notif
          notificationId: notifToSchedule,
        );
      }
    }catch (e) {
      developer.log(e.toString());
    }
  }

  void stopActiveAlarm() async{
    await _notificationService.cancelNotification(_currentNotificationId);
  }

  /// This function just returns what should be the next notif id
  /// It doesn't change the _currentNotificationId
  int _getNextRepeatId() {
    // If _currentNotificationId == 4 return 2
    if (_currentNotificationId >= NotificationService.repeatPoolId.last){
      return NotificationService.repeatPoolId[0];
    } else {
      return _currentNotificationId + 1;
    }
  }

  ClockActive _buildActiveState(DateTime clockedInAt, bool alarmEnabled) {
    final now       = DateTime.now();
    final elapsed   = now.difference(clockedInAt);
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
    _alertFiredSubscription?.cancel();
    return super.close();
  }
}

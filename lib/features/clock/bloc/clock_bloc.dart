import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import '../../../domain/use_cases/clock_in_use_case.dart';
import '../../../domain/use_cases/clock_out_use_case.dart';
import '../../../domain/repositories/active_session_repository.dart';
import '../../../domain/repositories/user_settings_repository.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/alarm_service.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

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
  final AlarmService                _alarmService;
  /// EndShiftNotification is 1
  /// RepeatNotifications are 2, 3, 4
  final List<int>           _validNotifIds = [1, 2, 3, 4];

  // Debug
  static const Duration _shiftDuration = Duration(seconds: 30);
  //static const Duration _shiftDuration = Duration(hours: 8);

  Timer?              _ticker;
  StreamSubscription? _alarmRingSubscription;
  StreamSubscription? _notificationActionSubscription;
  DateTime?           _nextAlarmAt;
  bool                _isRinging = false;
  int                 _currentNotificationId = 1;
  bool                _stopEndShiftAlarm = true;

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
    on<AlarmAutoDismissed>(_onAlarmAutoDismissed);

    _listenToAlarmRings();
    _listenToNotificationActions();
  }

  void _listenToAlarmRings() {
    _alarmRingSubscription = _alarmService.ringStream.listen((alarmSettings) {
      final id = alarmSettings.id;
      if (_validNotifIds.contains(id)) {
        add(AlertFired(id != NotificationService.shiftAlarmId));
      }
    });
  }

  void _listenToNotificationActions() {
    _notificationActionSubscription = _notificationService.actionStream.listen((action) {
      // Notification was dismissed — clear ringing state only, don't reschedule.
      // Rescheduling already happened in _onAlertFired when the alarm first fired.
    });
  }

  // ── Handlers ──────────────────────────────────────────────

  Future<void> _onStarted(
      ClockStarted event,
      Emitter<ClockState> emit,
      ) async {
    print('DEBUG: _onStarted called. Current _isRinging: $_isRinging');
    try {
      final active = await _repository.getActiveSession();
      if (active == null) {
        emit(ClockIdle(currentTime: DateTime.now()));
      } else {
        _startTicker();
        // Stop last notification if the app is opened
        // If its ringing, let _onAlarmStop handle it
        if (!active.alarmEnabled) {
          Timer(const Duration(seconds: 2), stopActiveAlarm);
          _currentNotificationId = _getNextRepeatId();
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

      print('DEBUG: Clocked in!');
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

      print('DEBUG: Clocked out!');
      emit(ClockIdle(currentTime: DateTime.now()));
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onAlarmStop(AlarmStopRequested event, Emitter<ClockState> emit) async {
    stopActiveAlarm();
    // Bump up the id
    _currentNotificationId = _getNextRepeatId();
    _isRinging = false;
    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  Future<void> _onAlarmAutoDismissed(AlarmAutoDismissed event, Emitter<ClockState> emit) async {
    // stopActiveAlarm();
    // // Bump up the id
    // _currentNotificationId = _getNextRepeatId();
    // _isRinging = false;
    // if (state case ClockActive active) {
    //   emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    // }
  }

  Future<void> _onAlarmToggled(
      AlarmToggled event,
      Emitter<ClockState> emit,
      ) async {
    print('DEBUG: Toggle pressed');
    await _repository.setAlarmSound(enabled: event.enabled);
    // cancel the current notif gracefully
    print('Canceling alarm: $_currentNotificationId');
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
    // Cancel last notif in case user didn't dismiss the alarm
    if (state case ClockActive active) {
      if (active.alarmEnabled) {
        _isRinging = true;
      }
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
    print('Alert fired! Scheduling next alarm!');
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
        print(
            'DEBUG: Scheduling shift end notification for $endOfShift');

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
        print(
            'DEBUG: Scheduling repeating notification at $nextRepeat');

        await _notificationService.scheduleRepeatNotification(
          scheduledDate: nextRepeat,
          delayMinutes: settings.alarmDelayMinutes,
          alarmEnabled: active!.alarmEnabled,
          // Alarm toggle needs to override current notif
          notificationId: override ? _currentNotificationId : _getNextRepeatId(),
        );
      }
    }catch (e) {
      print(e.toString());
    }
  }

  void stopActiveAlarm() async{
    await _notificationService.cancelNotification(_currentNotificationId);
  }

  /// This function just returns what should be the next notif id
  /// It doesn't change the _currentNotificationId
  int _getNextRepeatId() {
    // If _currentNotificationId == 4 return 2
    if (_currentNotificationId >= _validNotifIds[_validNotifIds.length - 1]){
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
    _alarmRingSubscription?.cancel();
    _notificationActionSubscription?.cancel();
    return super.close();
  }
}
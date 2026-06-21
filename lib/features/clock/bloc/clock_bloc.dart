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
    developer.log('DEBUG: _onStarted called. Current _isRinging: $_isRinging');
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
          developer.log('DEBUG: Scheduling shift end notification for $endOfShift');
          await _notificationService.scheduleShiftEndNotification(
            scheduledDate: endOfShift,
            delayMinutes:  settings.alarmDelayMinutes,
            alarmEnabled:  active.alarmEnabled,
          );
        } else {
          final delay = Duration(minutes: settings.alarmDelayMinutes);
          DateTime nextRepeat = endOfShift.add(delay);
          while (nextRepeat.isBefore(DateTime.now())) {
            nextRepeat = nextRepeat.add(delay);
          }
          developer.log('DEBUG: Scheduling repeating notification at $nextRepeat');
          _nextAlarmAt = nextRepeat;
          await _notificationService.scheduleRepeatNotification(
            scheduledDate: nextRepeat,
            delayMinutes: settings.alarmDelayMinutes,
            alarmEnabled: active.alarmEnabled,
            notificationId : _getNextRepeatId(),
          );
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

      developer.log('DEBUG: Clocked in!');
      final settings = await _settingsRepository.getSettings();
      final endOfShift = session.clockedInAt.add(_shiftDuration);
      _nextAlarmAt = endOfShift;

      await _notificationService.scheduleShiftEndNotification(
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

      await _notificationService.cancelAllShiftNotifications();
      _nextAlarmAt = endOfShift;

      await _notificationService.scheduleShiftEndNotification(
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
      ClockOutRequested event,
      Emitter<ClockState> emit,
      ) async {
    try {
      _ticker?.cancel();
      await _notificationService.cancelAllShiftNotifications();

      _nextAlarmAt             = null;
      _isRinging               = false;
      await _clockOut();

      developer.log('DEBUG: Clocked out!');
      emit(ClockIdle(currentTime: DateTime.now()));
    } catch (e) {
      emit(ClockError(e.toString()));
    }
  }

  Future<void> _onAlarmStop(AlarmStopRequested event, Emitter<ClockState> emit) async {
    int notifToCancel = _currentNotificationId - 1;
    developer.log('DEBUG: Notif stopped. Canceling id: $notifToCancel');
    await _notificationService.cancelNotification(notifToCancel);
    _isRinging = false;
    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  Future<void> _onAlarmAutoDismissed(AlarmAutoDismissed event, Emitter<ClockState> emit) async {
    int notifToCancel = _currentNotificationId - 1;
    developer.log('DEBUG: Notif auto dismissed. Canceling id: $notifToCancel');
    await _notificationService.cancelNotification(notifToCancel);
    _isRinging = false;
    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  Future<void> _onAlarmToggled(
      AlarmToggled event,
      Emitter<ClockState> emit,
      ) async {
    developer.log('DEBUG: Toggle pressed');
    await _repository.setAlarmSound(enabled: event.enabled);
    // cancel the current notif gracefully
    await _notificationService.cancelNotification(_currentNotificationId);

    if (state case ClockActive active) {
      final settings = await _settingsRepository.getSettings();
      final endOfShift = active.clockedInAt.add(_shiftDuration);

      // Schedule End shift notification if shift hasn't ended yet
      if (endOfShift.isAfter(DateTime.now())) {
        developer.log('DEBUG: Cancel all alarms, schedule end notif at $endOfShift');

        await _notificationService.scheduleShiftEndNotification(
          scheduledDate: endOfShift,
          delayMinutes:  settings.alarmDelayMinutes,
          alarmEnabled:  event.enabled,
        );
      } else { // Else schedule repeat shift notification
          developer.log('DEBUG: Schedule repeating notif at $_nextAlarmAt');
          await _notificationService.scheduleRepeatNotification(
            scheduledDate: _nextAlarmAt!,
            delayMinutes:  settings.alarmDelayMinutes,
            alarmEnabled:  event.enabled,
            notificationId: _currentNotificationId, // use current id to override it
          );
      }
      emit(_buildActiveState(active.clockedInAt, event.enabled));
    } else if (state case ClockIdle idle) {
      emit(ClockIdle(


        currentTime:  idle.currentTime,
        alarmEnabled: event.enabled,
      ));
    }
  }

  Future<void> _onAlertFired(AlertFired event, Emitter<ClockState> emit) async {
    // Cancel last notif to ensure its not ringing
    _notificationService.cancelNotification(_currentNotificationId - 1);
    if (state case ClockActive active) {
      if (active.alarmEnabled) {
        _isRinging = true;
      }
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
      add(const ClockStarted()); // schedule next
    }
  }

  void _onTicked(ClockTicked event, Emitter<ClockState> emit) {
    if (state case ClockActive active) {
      emit(_buildActiveState(active.clockedInAt, active.alarmEnabled));
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  int _getNextRepeatId() {
    _currentNotificationId++;
    if (_currentNotificationId >= _validNotifIds[_validNotifIds.length - 1]){
      _currentNotificationId = 2; // return to repeat notif ids
    }
    return _currentNotificationId;
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
import '../../core/services/notification_service.dart';
import '../../core/services/alarm_service.dart';

/// Concrete implementation of the Notification Service.
///
/// Everything is scheduled as a system alarm (via [AlarmService]/the `alarm`
/// package) so alerts get exact timing, wake the screen and override DND on
/// both platforms. When [alarmEnabled] is false the alarm still fires with
/// vibration + a notification, just without the audible ringtone.
class NotificationServiceImpl implements NotificationService {
  final AlarmService _alarmService;

  NotificationServiceImpl({required AlarmService alarmService}) : _alarmService = alarmService;

  @override
  Stream<int> get alertFiredStream =>
      _alarmService.ringStream.map((settings) => settings.id);

  @override
  Future<int?> currentlyRingingId() =>
      _alarmService.currentlyRingingId(NotificationService.allIds);

  @override
  Future<void> scheduleShiftEndNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
  }) async {
    await cancelAllShiftNotifications();

    await _alarmService.setAlarm(
      id: NotificationService.shiftAlarmId,
      dateTime: scheduledDate,
      title: 'Shift Over!',
      body: 'Your shift has ended. Time to clock out!',
      soundEnabled: alarmEnabled,
    );
  }

  @override
  Future<void> scheduleRepeatNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
    required int      notificationId,
  }) async {
    await _alarmService.setAlarm(
      id: notificationId,
      dateTime: scheduledDate,
      title: 'Overtime completed!',
      body: '+ $delayMinutes minutes. You can get a beer now.',
      soundEnabled: alarmEnabled,
    );
  }

  @override
  Future<void> cancelAllShiftNotifications() async {
    for (final id in NotificationService.allIds) {
      await _alarmService.stop(id);
    }
  }

  @override
  Future<void> cancelNotification(int id) => _alarmService.stop(id);
}

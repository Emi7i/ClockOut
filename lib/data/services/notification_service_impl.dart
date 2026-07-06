import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/alarm_service.dart';
import '../../core/utils/date_formatter.dart';

/// Concrete implementation of the Notification Service.
///
/// Everything is scheduled as a system alarm (via [AlarmService]/the `alarm`
/// package) so alerts get exact timing, wake the screen and override DND on
/// both platforms. When [alarmEnabled] is false the alarm still fires with
/// vibration + a notification, just without the audible ringtone.
class NotificationServiceImpl implements NotificationService {
  static const int _firedHistoryNotificationId = 100;
  static const String _firedHistoryChannelId = 'alert_history_channel';

  final AlarmService _alarmService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationServiceImpl({required AlarmService alarmService}) : _alarmService = alarmService;

  @override
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  @override
  Stream<int> get alertFiredStream =>
      _alarmService.ringStream.map((settings) => settings.id);

  @override
  Future<int?> currentlyRingingId() =>
      _alarmService.currentlyRingingId(NotificationService.allIds);

  @override
  Future<void> showAlertFiredNotification(DateTime firedAt) async {
    await _localNotifications.show(
      id: _firedHistoryNotificationId,
      title: 'Shift alert fired',
      body: 'Fired at ${DateFormatter.clockTime(firedAt)}',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _firedHistoryChannelId,
          'Alert history',
          channelDescription: 'Shows when the last shift alert fired',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
        ),
        iOS: DarwinNotificationDetails(presentSound: false),
      ),
    );
  }

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

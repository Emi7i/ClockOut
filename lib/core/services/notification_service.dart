import 'package:awesome_notifications/awesome_notifications.dart';

abstract interface class NotificationService {
  static const String alarmChannelKey = 'shift_end_alarm_channel';
  static const int shiftAlarmId  = 1;
  static const int repeatAlarmId = 2;
  static const int repeatAlarmIdAlt = 3;

  Stream<ReceivedAction> get actionStream;

  Future<void> initialize();
  Future<void> scheduleShiftEndNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
  });
  Future<void> scheduleRepeatNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
    int? id,
  });
  Future<void> cancelAllShiftNotifications();
  Future<void> cancelAllShiftNotificationsExcept(int id);
}

/// Called from main.dart as a TOP-LEVEL function (required by awesome_notifications
/// for background isolate execution).
/// Background isolates must set up their own repository builders.
@pragma('vm:entry-point')
Future<void> onNotificationActionReceived(ReceivedAction receivedAction) async {
  // This function is the entry point for the background isolate.
  // We need to re-import and re-setup if we were using builders, 
  // but since we want to avoid 'data' imports in core, we delegate to 
  // a handler that lives in the data layer.
}

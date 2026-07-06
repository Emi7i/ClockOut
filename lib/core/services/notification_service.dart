abstract interface class NotificationService {
  static const int shiftAlarmId = 1;
  static const List<int> repeatPoolId = [2, 3, 4];
  static const List<int> allIds = [shiftAlarmId, ...repeatPoolId];

  /// Emits the alert's id whenever a scheduled alert (sound or
  /// vibration-only) starts ringing.
  Stream<int> get alertFiredStream;

  /// Returns the id of the alert currently ringing, if any. Used to recover
  /// the ringing state after the app is cold-started or resumed.
  Future<int?> currentlyRingingId();

  Future<void> scheduleShiftEndNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
  });
  Future<void> scheduleRepeatNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
    required int      notificationId,
  });
  Future<void> cancelAllShiftNotifications();
  Future<void> cancelNotification(int id);
}

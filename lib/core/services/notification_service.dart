abstract interface class NotificationService {
  static const int shiftAlarmId = 1;
  static const List<int> repeatPoolId = [2, 3, 4];
  static const List<int> allIds = [shiftAlarmId, ...repeatPoolId];

  /// One-time setup for notification channels/permissions.
  Future<void> initialize();

  /// Emits the alert's id whenever a scheduled alert (sound or
  /// vibration-only) starts ringing.
  Stream<int> get alertFiredStream;

  /// Returns the id of the alert currently ringing, if any. Used to recover
  /// the ringing state after the app is cold-started or resumed.
  Future<int?> currentlyRingingId();

  /// Shows a plain, non-alarming notification recording when the last alert
  /// fired. Unlike the alarm's own notification, this one is independent of
  /// the alarm's ring/stop lifecycle, so it stays in the shade even after
  /// the alarm has been dismissed. Only one is ever shown at a time — each
  /// call replaces the previous one.
  Future<void> showAlertFiredNotification(DateTime firedAt);

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

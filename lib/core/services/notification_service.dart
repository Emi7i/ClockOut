import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleShiftEndNotification({
    required DateTime scheduledDate,
  });
  Future<void> cancelAllShiftNotifications();
}

/// Called from main.dart as a TOP-LEVEL function (required by awesome_notifications
/// for background isolate execution).
///
/// Wire it up in main.dart like this:
///
///   AwesomeNotifications().setListeners(
///     onActionReceivedMethod: NotificationController.onActionReceivedMethod,
///   );
@pragma('vm:entry-point')
Future<void> onNotificationActionReceived(ReceivedAction receivedAction) async {
  await NotificationController.onActionReceivedMethod(receivedAction);
}

/// Standalone controller holding the static callback — must be top-level or in
/// a class with only static members so the background isolate can reach it.
class NotificationController {
  static const int _baseNotificationId = 1;
  static const int _repeatNotificationId = 2;
  static const Duration _repeatInterval = Duration(minutes: 30);

  // Key stored in shared_preferences (or a simple static flag for same-process
  // scenarios) so we know whether a shift is still active.
  static bool _shiftActive = false;

  static void setShiftActive(bool active) => _shiftActive = active;

  /// Registered with AwesomeNotifications as the action handler.
  /// Runs in a background isolate when the app is killed.
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    final bool isDismissed =
        action.actionType == ActionType.DismissAction ||
            action.actionType == ActionType.SilentBackgroundAction;

    final bool isShiftNotification =
        action.id == _baseNotificationId ||
            action.id == _repeatNotificationId;

    if (isShiftNotification && isDismissed && _shiftActive) {
      // User dismissed the alarm without clocking out — reschedule in 30 min.
      await _scheduleRepeatAlarm();
    }
  }

  static Future<void> _scheduleRepeatAlarm() async {
    final DateTime next = DateTime.now().add(_repeatInterval);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _repeatNotificationId,
        channelKey: NotificationServiceImpl.alarmChannelKey,
        title: 'Still not clocked out!',
        body: 'Your shift ended a while ago. Please clock out.',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        autoDismissible: false,          // Forces the user to interact with it.
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.DismissAction,  // Triggers onActionReceivedMethod.
          isDangerousOption: false,
        ),
      ],
      schedule: NotificationCalendar.fromDate(date: next),
    );
  }
}

class NotificationServiceImpl implements NotificationService {
  static const String alarmChannelKey = 'shift_end_alarm_channel';

  @override
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: alarmChannelKey,
          channelName: 'Shift End Alarms',
          channelDescription: 'Alarm that repeats every 30 min until you clock out',
          defaultColor: const Color(0xFFC8F000),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          criticalAlerts: true,
          playSound: true,
          onlyAlertOnce: false,
        ),
      ],
      debug: true,
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Register the background-capable action handler.
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    );
  }

  @override
  Future<void> scheduleShiftEndNotification({
    required DateTime scheduledDate,
  }) async {
    await cancelAllShiftNotifications();

    // Mark shift as active so the repeat logic knows to keep firing.
    NotificationController.setShiftActive(true);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: NotificationController._baseNotificationId,
        channelKey: alarmChannelKey,
        title: 'Shift Over!',
        body: 'Your shift has ended. Time to clock out!',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        autoDismissible: false,
      ),
      // Add a Dismiss action button so awesome_notifications fires the callback
      // even when the user swipes away.
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.DismissAction,
        ),
      ],
      schedule: NotificationCalendar.fromDate(date: scheduledDate),
    );
  }

  @override
  Future<void> cancelAllShiftNotifications() async {
    // Mark shift as inactive FIRST so any in-flight callback does not
    // immediately reschedule after we cancel.
    NotificationController.setShiftActive(false);

    await AwesomeNotifications()
        .cancel(NotificationController._baseNotificationId);
    await AwesomeNotifications()
        .cancel(NotificationController._repeatNotificationId);
  }
}
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

abstract class NotificationService {
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
  });
  Future<void> cancelAllShiftNotifications();
}

/// Called from main.dart as a TOP-LEVEL function (required by awesome_notifications
/// for background isolate execution).
@pragma('vm:entry-point')
Future<void> onNotificationActionReceived(ReceivedAction receivedAction) async {
  await NotificationController.onActionReceivedMethod(receivedAction);
}

class NotificationController {
  static const int _baseNotificationId   = 1;
  static const int _repeatNotificationId = 2;

  static bool _shiftActive = false;
  static void setShiftActive(bool active) => _shiftActive = active;

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    final bool isDismissed =
        action.actionType == ActionType.DismissAction ||
            action.actionType == ActionType.SilentBackgroundAction;

    final bool isShiftNotification =
        action.id == _baseNotificationId ||
            action.id == _repeatNotificationId;

    // Check payload for repeat logic
    final bool repeatSoundEnabled = action.payload?['alarmEnabled'] == 'true';
    final int  delayMinutes       = int.tryParse(action.payload?['delayMinutes'] ?? '30') ?? 30;

    // ALWAYS reschedule if shift is active, regardless of sound toggle
    if (isShiftNotification && isDismissed && _shiftActive) {
      await _scheduleNextRepeat(delayMinutes, repeatSoundEnabled);
    }
  }

  static Future<void> _scheduleNextRepeat(int delayMinutes, bool soundEnabled) async {
    final DateTime next = DateTime.now().add(Duration(minutes: delayMinutes));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         _repeatNotificationId,
        channelKey: NotificationServiceImpl.alarmChannelKey,
        title:      'Still not clocked out!',
        body:       'Your shift ended a while ago. Please clock out.',
        category:   soundEnabled ? NotificationCategory.Alarm : NotificationCategory.Status,
        wakeUpScreen: soundEnabled,
        fullScreenIntent: soundEnabled,
        criticalAlert: soundEnabled,
        autoDismissible: false,
        payload: {
          'alarmEnabled': soundEnabled.toString(),
          'delayMinutes': delayMinutes.toString(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.DismissAction,
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
          channelKey:         alarmChannelKey,
          channelName:        'Shift End Alarms',
          channelDescription: 'Alarm that repeats until you clock out',
          defaultColor:       const Color(0xFFC8F000),
          importance:         NotificationImportance.Max,
          criticalAlerts:     true,
          playSound:          true,
        ),
      ],
      debug: true,
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    
    // Check and request exact alarm permission
    final List<NotificationPermission> permissions = await AwesomeNotifications().checkPermissionList(
      channelKey: alarmChannelKey,
      permissions: [
        NotificationPermission.PreciseAlarms,
        NotificationPermission.CriticalAlert,
        NotificationPermission.OverrideDnD,
      ],
    );

    if (permissions.isEmpty || !permissions.contains(NotificationPermission.PreciseAlarms)) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: alarmChannelKey,
        permissions: [
          NotificationPermission.PreciseAlarms,
          NotificationPermission.CriticalAlert,
          NotificationPermission.OverrideDnD,
        ],
      );
    }

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    );
  }

  @override
  Future<void> scheduleShiftEndNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
  }) async {
    await cancelAllShiftNotifications();
    NotificationController.setShiftActive(true);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         NotificationController._baseNotificationId,
        channelKey: alarmChannelKey,
        title:      'Shift Over!',
        body:       'Your shift has ended. Time to clock out!',
        category:   alarmEnabled ? NotificationCategory.Alarm : NotificationCategory.Status,
        wakeUpScreen: true,
        autoDismissible: false,
        payload: {
          'alarmEnabled': alarmEnabled.toString(),
          'delayMinutes': delayMinutes.toString(),
        },
      ),
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
  Future<void> scheduleRepeatNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
  }) async {
    // We use the same repeat ID to replace any existing one
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         NotificationController._repeatNotificationId,
        channelKey: alarmChannelKey,
        title:      'Still not clocked out!',
        body:       'Your shift ended a while ago. Please clock out.',
        category:   alarmEnabled ? NotificationCategory.Alarm : NotificationCategory.Status,
        wakeUpScreen: true,
        autoDismissible: false,
        payload: {
          'alarmEnabled': alarmEnabled.toString(),
          'delayMinutes': delayMinutes.toString(),
        },
      ),
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
    NotificationController.setShiftActive(false);
    await AwesomeNotifications().cancel(NotificationController._baseNotificationId);
    await AwesomeNotifications().cancel(NotificationController._repeatNotificationId);
  }
}
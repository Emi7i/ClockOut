import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import '../../data/datasources/database_manager.dart';
import '../../data/repositories/active_session_repository_impl.dart';

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

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    final bool isDismissed =
        action.actionType == ActionType.DismissAction ||
            action.actionType == ActionType.SilentBackgroundAction;

    if (isDismissed) {
      await Alarm.stop(action.id ?? 1);  // silence the hardware alarm

      // Initialize database and repository for background isolate
      final dbManager = DatabaseManager();
      final activeSessionRepo = ActiveSessionRepositoryImpl(dbManager);
      final active = await activeSessionRepo.getActiveSession();

      // ONLY reschedule if shift is still active in the database
      if (active != null) {
        final bool repeatSoundEnabled = action.payload?['alarmEnabled'] == 'true';
        final int  delayMinutes       = int.tryParse(action.payload?['delayMinutes'] ?? '30') ?? 30;
        
        await _scheduleNextRepeat(delayMinutes, repeatSoundEnabled);
      }
    }
  }

  static Future<void> _scheduleNextRepeat(int delayMinutes, bool soundEnabled) async {
    final DateTime next = DateTime.now().add(Duration(minutes: delayMinutes));

    // 1. Reschedule AwesomeNotification
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
      schedule: NotificationCalendar.fromDate(
        date: next,
        preciseAlarm: true,
      ),
    );

    // 2. Reschedule Hardware Alarm if enabled
    if (soundEnabled) {
      await Alarm.init();
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: _repeatNotificationId,
          dateTime: next,
          assetAudioPath: 'assets/alarm.mp3',
          loopAudio: true,
          vibrate: true,
          androidFullScreenIntent: true,
          volumeSettings: VolumeSettings.fade(
            volume: 0.8,
            fadeDuration: const Duration(seconds: 5),
            volumeEnforced: true,
          ),
          notificationSettings: NotificationSettings(
            title: 'Still not clocked out!',
            body: 'Your shift ended a while ago. Please clock out.',
            stopButton: 'Dismiss',
          ),
        ),
      );
    }
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
          onlyAlertOnce:      false,
          enableVibration:    true,
          defaultRingtoneType: DefaultRingtoneType.Notification, // Standard sound for toggle-off state
        ),
      ],
      debug: true,
    );

    final bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
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

    // 1. Schedule main shift-end notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         NotificationController._baseNotificationId,
        channelKey: alarmChannelKey,
        title:      'Shift Over!',
        body:       'Your shift has ended. Time to clock out!',
        category:   NotificationCategory.Alarm,
        criticalAlert: true,
        wakeUpScreen: true,
        fullScreenIntent: alarmEnabled,
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
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        preciseAlarm: true,
      ),
    );

    // 2. Automatically schedule the FIRST repeat notification too.
    await scheduleRepeatNotification(
      scheduledDate: scheduledDate.add(Duration(minutes: delayMinutes)),
      delayMinutes:  delayMinutes,
      alarmEnabled:  alarmEnabled,
    );
  }

  @override
  Future<void> scheduleRepeatNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         NotificationController._repeatNotificationId,
        channelKey: alarmChannelKey,
        title:      'Still not clocked out!',
        body:       'Your shift ended a while ago. Please clock out.',
        category:   NotificationCategory.Alarm,
        criticalAlert: true,
        wakeUpScreen: true,
        fullScreenIntent: alarmEnabled,
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
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        preciseAlarm: true,
      ),
    );
  }

  @override
  Future<void> cancelAllShiftNotifications() async {
    await AwesomeNotifications().cancel(NotificationController._baseNotificationId);
    await AwesomeNotifications().cancel(NotificationController._repeatNotificationId);
  }
}

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import '../../domain/repositories/active_session_repository.dart';
import '../../core/services/notification_service.dart';

/// Concrete implementation of the Notification Service.
/// Located in data layer because background logic needs repository access.
class NotificationServiceImpl implements NotificationService {
  @override
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey:         NotificationService.alarmChannelKey,
          channelName:        'Shift End Alarms',
          channelDescription: 'Alarm that repeats until you clock out',
          defaultColor:       const Color(0xFFC8F000),
          importance:         NotificationImportance.Max,
          criticalAlerts:     true,
          playSound:          true,
          onlyAlertOnce:      false,
          enableVibration:    true,
          defaultRingtoneType: DefaultRingtoneType.Notification,
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

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         NotificationController.baseNotificationId,
        channelKey: NotificationService.alarmChannelKey,
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
        id:         NotificationController.repeatNotificationId,
        channelKey: NotificationService.alarmChannelKey,
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
    await AwesomeNotifications().cancel(NotificationController.baseNotificationId);
    await AwesomeNotifications().cancel(NotificationController.repeatNotificationId);
  }
}

/// Controller for background notification actions.
class NotificationController {
  static const int baseNotificationId   = 1;
  static const int repeatNotificationId = 2;

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    final bool isDismissed =
        action.actionType == ActionType.DismissAction ||
            action.actionType == ActionType.SilentBackgroundAction;

    if (isDismissed) {
      await Alarm.stop(action.id ?? 1);

      // In background isolate, ensure repositories are ready
      // We use the build factory which should be set in onNotificationActionReceived
      final activeSessionRepo = ActiveSessionRepository.build();
      final active = await activeSessionRepo.getActiveSession();

      if (active != null) {
        final bool repeatSoundEnabled = action.payload?['alarmEnabled'] == 'true';
        final int  delayMinutes       = int.tryParse(action.payload?['delayMinutes'] ?? '30') ?? 30;
        
        await _scheduleNextRepeat(delayMinutes, repeatSoundEnabled);
      }
    }
  }

  static Future<void> _scheduleNextRepeat(int delayMinutes, bool soundEnabled) async {
    final DateTime next = DateTime.now().add(Duration(minutes: delayMinutes));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         repeatNotificationId,
        channelKey: NotificationService.alarmChannelKey,
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

    if (soundEnabled) {
      await Alarm.init();
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: repeatNotificationId,
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

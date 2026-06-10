import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleShiftEndNotification({
    required DateTime scheduledDate,
    required bool withAlarm,
  });
  Future<void> cancelAllShiftNotifications();
}

class NotificationServiceImpl implements NotificationService {
  static const String channelKey = 'shift_end_channel';
  static const String alarmChannelKey = 'shift_end_alarm_channel';

  @override
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // Use default icon
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Shift End Notifications',
          channelDescription: 'Notification sent at the end of your shift',
          defaultColor: const Color(0xFFC8F000),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: alarmChannelKey,
          channelName: 'Shift End Alarms',
          channelDescription: 'Alarm notification with sound at the end of your shift',
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

    // Request permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  @override
  Future<void> scheduleShiftEndNotification({
    required DateTime scheduledDate,
    required bool withAlarm,
  }) async {
    // Cancel any existing notifications for shift end
    await cancelAllShiftNotifications();

    final String selectedChannel = withAlarm ? alarmChannelKey : channelKey;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: selectedChannel,
        title: 'Shift Over!',
        body: 'Your shift has ended. Time to clock out!',
        notificationLayout: NotificationLayout.Default,
        category: withAlarm ? NotificationCategory.Alarm : NotificationCategory.Reminder,
        wakeUpScreen: true,
        fullScreenIntent: withAlarm,
        criticalAlert: withAlarm,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduledDate),
    );
  }

  @override
  Future<void> cancelAllShiftNotifications() async {
    await AwesomeNotifications().cancel(1);
  }
}

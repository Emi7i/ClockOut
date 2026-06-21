import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:alarm/alarm.dart';
import '../../core/constants/constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/alarm_service.dart';

/// Concrete implementation of the Notification Service.
/// Located in data layer because background logic needs repository access.
class NotificationServiceImpl implements NotificationService {
  final AlarmService _alarmService;

  NotificationServiceImpl({required AlarmService alarmService}) : _alarmService = alarmService;

  @override
  Stream<ReceivedAction> get actionStream => NotificationController.actionStream;

  @override
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey:       NotificationService.alarmChannelKey,
          channelName:      'Shift End Alarms',
          channelDescription: 'Alarm that repeats until you clock out',
          defaultColor:     AppColors.accent,
          importance:       NotificationImportance.Max,
          criticalAlerts:   true,
          playSound:        true,
          onlyAlertOnce:    false,
          enableVibration:  true,
          vibrationPattern: Int64List.fromList([
            0, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800, 400, 800,
            // ~10.5 seconds: 7× (800ms on + 400ms off)
          ]),
        ),
      ],
      debug: true,
    );

    final bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  @override
  Future<void> scheduleShiftEndNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
  }) async {
    await cancelAllShiftNotifications();

    // 1. Schedule the notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         NotificationService.shiftAlarmId,
        channelKey: NotificationService.alarmChannelKey,
        title:      'Shift Over!',
        body:       'Your shift has ended. Time to clock out!',
        // DO NOT TOUCH THESE PARAMETERS
        category:   NotificationCategory.Alarm,
        criticalAlert: true,
        wakeUpScreen: false,
        fullScreenIntent: false,
        autoDismissible: true, // dismiss notif if user taps on it
        payload: {
          'alarmEnabled': alarmEnabled.toString(),
          'delayMinutes': delayMinutes.toString(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.Default, // Opens the app
        ),
      ],
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        preciseAlarm: true,
      ),
    );

    developer.log('Scheduling end shift alarm at: $scheduledDate (now: ${DateTime.now()})');

    // 2. Schedule the hardware alarm if enabled
    if (alarmEnabled) {
      developer.log('Scheduling normal alarm at: $scheduledDate (now: ${DateTime.now()})');
      await _alarmService.setAlarm(
        id: NotificationService.shiftAlarmId,
        dateTime: scheduledDate,
        title: 'Shift Over!',
        body: 'You earned a good rest!',
      );
    }
  }

  @override
  Future<void> scheduleRepeatNotification({
    required DateTime scheduledDate,
    required int      delayMinutes,
    required bool     alarmEnabled,
    required int      notificationId,
  }) async {
    // 1. Schedule the notification
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id:         notificationId,
        channelKey: NotificationService.alarmChannelKey,
        title:      'Overtime completed!',
        body:       '+ 30 minutes. You can get a beer now.',
        // DO NOT TOUCH THESE PARAMETERS
        category:   NotificationCategory.Alarm,
        criticalAlert: true,
        wakeUpScreen: false,
        fullScreenIntent: false,
        autoDismissible: true, // dismiss notif if user taps on it
        payload: {
          'alarmEnabled': alarmEnabled.toString(),
          'delayMinutes': delayMinutes.toString(),
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.Default, // Opens the app
        ),
      ],
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        preciseAlarm: true,
      ),
    );

    developer.log('Scheduling repeat alarm at: $scheduledDate (now: ${DateTime.now()})');

    // 2. Schedule hardware alarm if enabled
    if (alarmEnabled) {
      await _alarmService.setAlarm(
        id: notificationId,
        dateTime: scheduledDate,
        title: 'alarm!',
        body: 'Your shift ended a while ago. Please clock out.',
      );
    }
  }

  @override
  Future<void> cancelAllShiftNotifications() async {
    await AwesomeNotifications().cancel(NotificationService.shiftAlarmId);
    await _alarmService.stop(NotificationService.shiftAlarmId);  // cancel sound
    for (int notifId in NotificationService.repeatPoolId){
      await AwesomeNotifications().cancel(notifId);
      await _alarmService.stop(notifId);  // cancel sound
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
    await _alarmService.stop(id);  // cancel sound
  }
}

/// Controller for background notification actions.
class NotificationController {
  static final _actionStreamController = StreamController<ReceivedAction>.broadcast();

  static Stream<ReceivedAction> get actionStream => _actionStreamController.stream;

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    // Stop the hardware alarm on dismiss
    await Alarm.stop(action.id ?? NotificationService.shiftAlarmId);

    _actionStreamController.add(action);
    // The requirement is that dismiss opens the app and nothing else.
    // By setting ActionType.Default on the button, the app will open.
    // We don't need to do any rescheduling here - ClockStarted will handle it.
  }
}

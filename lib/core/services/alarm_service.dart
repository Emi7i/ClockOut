import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm/model/notification_settings.dart';
import 'package:alarm/model/volume_settings.dart';

abstract class AlarmService {
  Stream<AlarmSettings> get ringStream;
  
  /// Schedules an alarm with the project's standard visual and audio settings.
  Future<void> setAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  });
  
  Future<bool> stop(int id);
  Future<void> init();
}

class AlarmServiceImpl implements AlarmService {
  @override
  Stream<AlarmSettings> get ringStream => Alarm.ringStream.stream;

  @override
  Future<void> setAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: const Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Dismiss',
        icon: 'notification_icon',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  @override
  Future<bool> stop(int id) => Alarm.stop(id);

  @override
  Future<void> init() => Alarm.init();
}

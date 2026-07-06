import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';

abstract class AlarmService {
  /// Fires whenever an alarm starts ringing (sound or vibration-only).
  Stream<AlarmSettings> get ringStream;

  /// Schedules an alarm with the project's standard visual/haptic settings.
  ///
  /// When [soundEnabled] is true, the alarm plays the loud alarm ringtone.
  /// When false, it plays a silent asset instead — the device still vibrates,
  /// wakes the screen and shows the notification, but stays quiet.
  Future<void> setAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    required bool soundEnabled,
  });

  Future<bool> stop(int id);
  Future<void> init();

  /// Returns the id of the alarm currently ringing among [ids], if any.
  Future<int?> currentlyRingingId(List<int> ids);
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
    required bool soundEnabled,
  }) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: soundEnabled ? 'assets/alarm.mp3' : 'assets/silence.wav',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      // Without this, a new alert is silently dropped (no sound, no
      // vibration, nothing) whenever a previous one is still ringing —
      // e.g. the user missed dismissing the last repeat in time.
      allowAlarmOverlap: true,
      volumeSettings: soundEnabled
          ? VolumeSettings.fade(
              volume: 0.8,
              fadeDuration: const Duration(seconds: 5),
              volumeEnforced: true,
            )
          : VolumeSettings.fixed(
              volume: 0,
              volumeEnforced: true,
              showSystemUI: false,
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

  @override
  Future<int?> currentlyRingingId(List<int> ids) async {
    for (final id in ids) {
      if (await Alarm.isRinging(id)) return id;
    }
    return null;
  }
}

import 'dart:async';
import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';

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
  Stream<AlarmSettings> get ringStream {
    // Alarm.ringing is a value stream that replays the currently-ringing
    // set on every listen. Diff consecutive sets so we only emit alarms
    // transitioning into ringing after subscription — matching the old
    // ringStream field, which never replayed pre-existing state. Recovery
    // of an already-ringing alarm on cold start is handled separately via
    // currentlyRingingId().
    AlarmSet? previous;
    return Alarm.ringing.expand((current) {
      final prior = previous;
      previous = current;
      if (prior == null) return const <AlarmSettings>[];
      return current.alarms.where((a) => !prior.containsId(a.id));
    });
  }

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

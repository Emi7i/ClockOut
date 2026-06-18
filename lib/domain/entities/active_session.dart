/// ─────────────────────────────────────────────────────────────
///  ACTIVE SESSION  –  Domain Entity
///  Represents a single active clock-in session.
///  Plain Dart: no framework dependencies.
/// ─────────────────────────────────────────────────────────────
class ActiveSession {
  final DateTime clockedInAt;
  final int? nextAlarmIn;
  final Duration accumulatedBonusTime;
  final bool alarmEnabled;

  const ActiveSession({
    required this.clockedInAt,
    this.nextAlarmIn,
    this.accumulatedBonusTime = Duration.zero,
    this.alarmEnabled = false,
  });

  Duration get elapsed {
    return DateTime.now().difference(clockedInAt);
  }

  ActiveSession copyWith({
    DateTime? clockedInAt,
    int? nextAlarmIn,
    Duration? accumulatedBonusTime,
    bool? alarmEnabled,
  }) {
    return ActiveSession(
      clockedInAt: clockedInAt ?? this.clockedInAt,
      nextAlarmIn: nextAlarmIn ?? this.nextAlarmIn,
      accumulatedBonusTime: accumulatedBonusTime ?? this.accumulatedBonusTime,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    );
  }
}

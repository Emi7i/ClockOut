/// ─────────────────────────────────────────────────────────────
///  ACTIVE SESSION DTO
///  Data Transfer Object for the ActiveSession table in SQLite.
/// ─────────────────────────────────────────────────────────────
class ActiveSessionDto {
  final String clockedInTime;
  final int? nextAlarmIn;
  final int accumulatedBonusTime;
  final int alarmOn; // 0 or 1

  const ActiveSessionDto({
    required this.clockedInTime,
    this.nextAlarmIn,
    required this.accumulatedBonusTime,
    required this.alarmOn,
  });

  factory ActiveSessionDto.fromMap(Map<String, dynamic> map) {
    return ActiveSessionDto(
      clockedInTime:          map['clocked_in_time'] as String,
      nextAlarmIn:            map['next_alarm_in'] as int?,
      accumulatedBonusTime:   map['accumulated_bonus_time'] as int,
      alarmOn:                map['alarm_on'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clocked_in_time':          clockedInTime,
      'next_alarm_in':            nextAlarmIn,
      'accumulated_bonus_time':   accumulatedBonusTime,
      'alarm_on':                alarmOn,
    };
  }
}

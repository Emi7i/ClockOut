/// ─────────────────────────────────────────────────────────────
///  USER SETTINGS  –  Domain Entity
///  Pure Dart: No dependencies on Flutter UI (like Color).
/// ─────────────────────────────────────────────────────────────
class UserSettings {
  /// Hex value of the accent color (e.g., 0xFF4CAF50).
  final int accentColorHex;

  /// true = 12-hour clock, false = 24-hour clock.
  final bool is12HourFormat;

  /// Alarm delay increment in minutes.
  final int alarmDelayMinutes;

  const UserSettings({
    required this.accentColorHex,
    required this.is12HourFormat,
    required this.alarmDelayMinutes,
  });

  UserSettings copyWith({
    int?  accentColorHex,
    bool? is12HourFormat,
    int?  alarmDelayMinutes,
  }) {
    return UserSettings(
      accentColorHex:    accentColorHex    ?? this.accentColorHex,
      is12HourFormat:    is12HourFormat    ?? this.is12HourFormat,
      alarmDelayMinutes: alarmDelayMinutes ?? this.alarmDelayMinutes,
    );
  }
}

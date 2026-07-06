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

  /// Hex values of the last few distinct accent colors picked, most
  /// recent first. Capped by whoever writes it (see SettingsBloc).
  final List<int> recentAccentColors;

  const UserSettings({
    required this.accentColorHex,
    required this.is12HourFormat,
    required this.alarmDelayMinutes,
    this.recentAccentColors = const [],
  });

  UserSettings copyWith({
    int?  accentColorHex,
    bool? is12HourFormat,
    int?  alarmDelayMinutes,
    List<int>? recentAccentColors,
  }) {
    return UserSettings(
      accentColorHex:    accentColorHex    ?? this.accentColorHex,
      is12HourFormat:    is12HourFormat    ?? this.is12HourFormat,
      alarmDelayMinutes: alarmDelayMinutes ?? this.alarmDelayMinutes,
      recentAccentColors: recentAccentColors ?? this.recentAccentColors,
    );
  }
}

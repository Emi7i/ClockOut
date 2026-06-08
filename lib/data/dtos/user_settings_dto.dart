/// ─────────────────────────────────────────────────────────────
///  USER SETTINGS DTO
///  Data Transfer Object for the UserSettings table in SQLite.
/// ─────────────────────────────────────────────────────────────
class UserSettingsDto {
  final int? id;
  final String? accentColor;
  final String? clockFormat;
  final int timeDelay;

  const UserSettingsDto({
    this.id,
    this.accentColor,
    this.clockFormat,
    required this.timeDelay,
  });

  factory UserSettingsDto.fromMap(Map<String, dynamic> map) {
    return UserSettingsDto(
      id:          map['settings_id'] as int?,
      accentColor: map['accent_color'] as String?,
      clockFormat: map['clock_format'] as String?,
      timeDelay:   map['time_delay'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'settings_id': id,
      'accent_color': accentColor,
      'clock_format': clockFormat,
      'time_delay':   timeDelay,
    };
  }
}

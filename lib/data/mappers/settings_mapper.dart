import '../../domain/entities/user_settings.dart';
import '../dtos/user_settings_dto.dart';

class SettingsMapper {
  static UserSettings toEntity(UserSettingsDto dto) {
    return UserSettings(
      accentColorHex:    int.tryParse(dto.accentColor ?? '0xFF4CAF50') ?? 0xFF4CAF50,
      is12HourFormat:    dto.clockFormat == '12h',
      alarmDelayMinutes: dto.timeDelay,
      recentAccentColors: (dto.recentColors ?? '')
          .split(',')
          .map((s) => int.tryParse(s))
          .whereType<int>()
          .toList(),
    );
  }

  static UserSettingsDto toDto(UserSettings entity, {int? id}) {
    return UserSettingsDto(
      id:          id,
      accentColor: '0x${entity.accentColorHex.toRadixString(16).toUpperCase()}',
      clockFormat: entity.is12HourFormat ? '12h' : '24h',
      timeDelay:   entity.alarmDelayMinutes,
      recentColors: entity.recentAccentColors
          .map((hex) => '0x${hex.toRadixString(16).toUpperCase()}')
          .join(','),
    );
  }
}

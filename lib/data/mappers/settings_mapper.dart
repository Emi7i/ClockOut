import '../../domain/entities/user_settings.dart';
import '../dtos/user_settings_dto.dart';

class SettingsMapper {
  static UserSettings toDomain(UserSettingsDto dto) {
    // Convert hex string (e.g., "0xFF4CAF50") to int
    final hexString = dto.accentColor ?? '0xFF4CAF50';
    final hexInt = int.tryParse(hexString) ?? 0xFF4CAF50;

    return UserSettings(
      accentColorHex:    hexInt,
      is12HourFormat:    dto.clockFormat == '12h',
      alarmDelayMinutes: dto.timeDelay,
    );
  }

  static UserSettingsDto fromDomain(UserSettings entity) {
    return UserSettingsDto(
      accentColor: '0x${entity.accentColorHex.toRadixString(16).toUpperCase()}',
      clockFormat: entity.is12HourFormat ? '12h' : '24h',
      timeDelay:   entity.alarmDelayMinutes,
    );
  }
}

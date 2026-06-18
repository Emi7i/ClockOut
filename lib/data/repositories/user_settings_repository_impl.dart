import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../datasources/database_manager.dart';
import '../mappers/settings_mapper.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  final DatabaseManager _dbManager;

  UserSettingsRepositoryImpl(this._dbManager);

  @override
  Future<UserSettings> getSettings() async {
    final dto = await _dbManager.getSettings();
    if (dto == null) {
      // Should not happen due to seeding, but providing fallback
      return const UserSettings(
        accentColorHex: 0xFF4CAF50,
        is12HourFormat: false,
        alarmDelayMinutes: 30,
      );
    }
    return SettingsMapper.toEntity(dto);
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    final currentDto = await _dbManager.getSettings();
    final dto = SettingsMapper.toDto(settings, id: currentDto?.id ?? 1);
    await _dbManager.updateSettings(dto);
  }
}

import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../datasources/database_manager.dart';
import '../mappers/settings_mapper.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  final DatabaseManager _dbManager;

  UserSettingsRepositoryImpl({DatabaseManager? dbManager}) 
      : _dbManager = dbManager ?? DatabaseManager();

  @override
  Future<UserSettings> getSettings() async {
    final dto = await _dbManager.getSettings();
    if (dto == null) {
      // Return defaults if somehow not seeded
      return const UserSettings(
        accentColorHex:    0xFF4CAF50,
        is12HourFormat:    false,
        alarmDelayMinutes: 30,
      );
    }
    return SettingsMapper.toDomain(dto);
  }

  @override
  Future<void> updateSettings(UserSettings settings) async {
    await _dbManager.updateSettings(SettingsMapper.fromDomain(settings));
  }
}

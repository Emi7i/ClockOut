import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/data/dtos/user_settings_dto.dart';
import 'package:clock_app/data/mappers/settings_mapper.dart';
import 'package:clock_app/domain/entities/user_settings.dart';

void main() {
  group('SettingsMapper', () {
    test('toDomain should map correctly', () {
      const dto = UserSettingsDto(
        id: 1,
        accentColor: '0xFFC8F000',
        clockFormat: '12h',
        timeDelay: 15,
      );

      final entity = SettingsMapper.toDomain(dto);

      expect(entity.accentColorHex, 0xFFC8F000);
      expect(entity.is12HourFormat, true);
      expect(entity.alarmDelayMinutes, 15);
    });

    test('fromDomain should map correctly', () {
      const entity = UserSettings(
        accentColorHex: 0xFFC8F000,
        is12HourFormat: false,
        alarmDelayMinutes: 30,
      );

      final dto = SettingsMapper.fromDomain(entity);

      expect(dto.accentColor, '0xFFC8F000');
      expect(dto.clockFormat, '24h');
      expect(dto.timeDelay, 30);
    });
  });
}

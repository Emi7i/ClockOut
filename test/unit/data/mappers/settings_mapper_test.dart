import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/data/dtos/user_settings_dto.dart';
import 'package:clock_app/data/mappers/settings_mapper.dart';
import 'package:clock_app/domain/entities/user_settings.dart';

void main() {
  group('SettingsMapper', () {
    test('toEntity should map correctly', () {
      const dto = UserSettingsDto(
        id: 1,
        accentColor: '0xFFC8F000',
        clockFormat: '12h',
        timeDelay: 15,
      );

      final entity = SettingsMapper.toEntity(dto);

      expect(entity.accentColorHex, 0xFFC8F000);
      expect(entity.is12HourFormat, true);
      expect(entity.alarmDelayMinutes, 15);
    });

    test('toDto should map correctly', () {
      const entity = UserSettings(
        accentColorHex: 0xFFC8F000,
        is12HourFormat: false,
        alarmDelayMinutes: 30,
      );

      final dto = SettingsMapper.toDto(entity, id: 1);

      expect(dto.id, 1);
      expect(dto.accentColor, '0xFFC8F000');
      expect(dto.clockFormat, '24h');
      expect(dto.timeDelay, 30);
    });

    test('toEntity defaults recentAccentColors to empty when column is null', () {
      const dto = UserSettingsDto(accentColor: '0xFFC8F000', timeDelay: 30);

      expect(SettingsMapper.toEntity(dto).recentAccentColors, isEmpty);
    });

    test('recentAccentColors round-trips through toDto/toEntity', () {
      const entity = UserSettings(
        accentColorHex: 0xFFC8F000,
        is12HourFormat: false,
        alarmDelayMinutes: 30,
        recentAccentColors: [0xFFAABBCC, 0xFF112233],
      );

      final dto = SettingsMapper.toDto(entity);
      final roundTripped = SettingsMapper.toEntity(dto);

      expect(roundTripped.recentAccentColors, [0xFFAABBCC, 0xFF112233]);
    });
  });
}

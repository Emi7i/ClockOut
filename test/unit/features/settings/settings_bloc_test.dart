import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock_app/domain/entities/user_settings.dart';
import 'package:clock_app/domain/repositories/user_settings_repository.dart';
import 'package:clock_app/domain/repositories/log_repository.dart';
import 'package:clock_app/features/settings/bloc/settings_bloc.dart';

class MockUserSettingsRepository extends Mock implements UserSettingsRepository {}
class MockLogRepository extends Mock implements LogRepository {}

class UserSettingsFake extends Fake implements UserSettings {}

void main() {
  late MockUserSettingsRepository mockSettingsRepo;
  late MockLogRepository mockLogRepo;

  setUpAll(() {
    registerFallbackValue(UserSettingsFake());
  });

  setUp(() {
    mockSettingsRepo = MockUserSettingsRepository();
    mockLogRepo = MockLogRepository();
  });

  group('SettingsBloc', () {
    const tSettings = UserSettings(
      accentColorHex: 0xFF4CAF50,
      is12HourFormat: false,
      alarmDelayMinutes: 30,
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [SettingsLoaded] when SettingsStarted succeeds',
      build: () {
        when(() => mockSettingsRepo.getSettings()).thenAnswer((_) async => tSettings);
        return SettingsBloc(
          settingsRepo: mockSettingsRepo,
          logRepo: mockLogRepo,
        );
      },
      act: (bloc) => bloc.add(const SettingsStarted()),
      expect: () => [
        isA<SettingsLoaded>(),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits updated state and calls repository when ClockFormatToggled',
      build: () {
        when(() => mockSettingsRepo.getSettings()).thenAnswer((_) async => tSettings);
        when(() => mockSettingsRepo.updateSettings(any())).thenAnswer((_) async => {});
        return SettingsBloc(
          settingsRepo: mockSettingsRepo,
          logRepo: mockLogRepo,
        );
      },
      seed: () => SettingsLoaded(
        accentColor: Color(tSettings.accentColorHex),
        is12HourFormat: tSettings.is12HourFormat,
        alarmDelayMinutes: tSettings.alarmDelayMinutes,
      ),
      act: (bloc) => bloc.add(const ClockFormatToggled()),
      expect: () => [
        isA<SettingsLoaded>().having((s) => s.is12HourFormat, 'is12HourFormat', true),
      ],
      verify: (_) {
        verify(() => mockSettingsRepo.updateSettings(any())).called(1);
      },
    );
  });
}

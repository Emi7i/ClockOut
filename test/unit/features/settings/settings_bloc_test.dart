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

    blocTest<SettingsBloc, SettingsState>(
      'adds a newly picked accent color to the front of recentColors',
      build: () {
        when(() => mockSettingsRepo.updateSettings(any())).thenAnswer((_) async => {});
        return SettingsBloc(
          settingsRepo: mockSettingsRepo,
          logRepo: mockLogRepo,
        );
      },
      seed: () => const SettingsLoaded(
        accentColor: Color(0xFFC8F000),
        is12HourFormat: false,
        alarmDelayMinutes: 30,
        recentColors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
      ),
      act: (bloc) => bloc.add(const AccentColorChanged(Color(0xFFFF4081))),
      expect: () => [
        isA<SettingsLoaded>().having(
          (s) => s.recentColors,
          'recentColors',
          const [Color(0xFFFF4081), Color(0xFF00E5FF), Color(0xFF7C4DFF)],
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'does not duplicate a color already in recentColors, and caps at 5',
      build: () {
        when(() => mockSettingsRepo.updateSettings(any())).thenAnswer((_) async => {});
        return SettingsBloc(
          settingsRepo: mockSettingsRepo,
          logRepo: mockLogRepo,
        );
      },
      seed: () => const SettingsLoaded(
        accentColor: Color(0xFFC8F000),
        is12HourFormat: false,
        alarmDelayMinutes: 30,
        recentColors: [
          Color(0xFF00E5FF),
          Color(0xFF7C4DFF),
          Color(0xFFFF4081),
          Color(0xFFFFAB40),
          Color(0xFF69F0AE),
        ],
      ),
      act: (bloc) => bloc.add(const AccentColorChanged(Color(0xFF7C4DFF))),
      expect: () => [
        isA<SettingsLoaded>().having(
          (s) => s.recentColors,
          'recentColors',
          const [
            Color(0xFF7C4DFF),
            Color(0xFF00E5FF),
            Color(0xFFFF4081),
            Color(0xFFFFAB40),
            Color(0xFF69F0AE),
          ],
        ),
      ],
    );
  });
}

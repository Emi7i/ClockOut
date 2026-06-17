import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock_app/domain/entities/clock_entry.dart';
import 'package:clock_app/domain/entities/user_settings.dart';
import 'package:clock_app/domain/repositories/clock_repository.dart';
import 'package:clock_app/domain/repositories/user_settings_repository.dart';
import 'package:clock_app/domain/use_cases/clock_in_use_case.dart';
import 'package:clock_app/domain/use_cases/clock_out_use_case.dart';
import 'package:clock_app/features/clock/bloc/clock_bloc.dart';
import 'package:clock_app/core/services/notification_service.dart';
import 'package:clock_app/core/services/alarm_service.dart';
import 'package:alarm/model/alarm_settings.dart';

class MockClockRepository extends Mock implements ClockRepository {}
class MockUserSettingsRepository extends Mock implements UserSettingsRepository {}
class MockClockInUseCase extends Mock implements ClockInUseCase {}
class MockClockOutUseCase extends Mock implements ClockOutUseCase {}
class MockNotificationService extends Mock implements NotificationService {}
class MockAlarmService extends Mock implements AlarmService {}
class FakeAlarmSettings extends Fake implements AlarmSettings {}

void main() {
  late MockClockRepository mockRepository;
  late MockUserSettingsRepository mockSettingsRepository;
  late MockClockInUseCase mockClockIn;
  late MockClockOutUseCase mockClockOut;
  late MockNotificationService mockNotificationService;
  late MockAlarmService mockAlarmService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(FakeAlarmSettings());
  });

  setUp(() {
    mockRepository = MockClockRepository();
    mockSettingsRepository = MockUserSettingsRepository();
    mockClockIn = MockClockInUseCase();
    mockClockOut = MockClockOutUseCase();
    mockNotificationService = MockNotificationService();
    mockAlarmService = MockAlarmService();

    // Default mock behaviors
    when(() => mockSettingsRepository.getSettings()).thenAnswer((_) async => const UserSettings(
          accentColorHex: 0xFF4CAF50,
          is12HourFormat: false,
          alarmDelayMinutes: 30,
        ));
    when(() => mockNotificationService.scheduleShiftEndNotification(
          scheduledDate: any(named: 'scheduledDate'),
          delayMinutes:  any(named: 'delayMinutes'),
          alarmEnabled:  any(named: 'alarmEnabled'),
        )).thenAnswer((_) async => {});
    when(() => mockNotificationService.scheduleRepeatNotification(
          scheduledDate: any(named: 'scheduledDate'),
          delayMinutes:  any(named: 'delayMinutes'),
          alarmEnabled:  any(named: 'alarmEnabled'),
        )).thenAnswer((_) async => {});
    when(() => mockNotificationService.cancelAllShiftNotifications())
        .thenAnswer((_) async => {});
    
    when(() => mockAlarmService.ringStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAlarmService.setAlarm(
          id: any(named: 'id'),
          dateTime: any(named: 'dateTime'),
          title: any(named: 'title'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => {});
    when(() => mockAlarmService.stop(any())).thenAnswer((_) async => true);
  });

  group('ClockBloc', () {
    final tClockEntry = ClockEntry(
      id: '1',
      clockedInAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    blocTest<ClockBloc, ClockState>(
      'emits [ClockIdle] when ClockStarted finds no active entry',
      build: () {
        when(() => mockRepository.getActiveEntry()).thenAnswer((_) async => null);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
          alarmService: mockAlarmService,
        );
      },
      act: (bloc) => bloc.add(const ClockStarted()),
      expect: () => [
        isA<ClockIdle>(),
      ],
    );

    blocTest<ClockBloc, ClockState>(
      'emits [ClockActive] when ClockStarted finds active entry',
      build: () {
        when(() => mockRepository.getActiveEntry()).thenAnswer((_) async => tClockEntry);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
          alarmService: mockAlarmService,
        );
      },
      act: (bloc) => bloc.add(const ClockStarted()),
      expect: () => [
        isA<ClockActive>(),
      ],
    );

    blocTest<ClockBloc, ClockState>(
      'emits [ClockActive] with nextAlarmIn when ClockInRequested succeeds and alarm is enabled',
      build: () {
        final entry = ClockEntry(
          id: '1',
          clockedInAt: DateTime.now(),
          alarmEnabled: true,
        );
        when(() => mockClockIn()).thenAnswer((_) async => entry);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
          alarmService: mockAlarmService,
        );
      },
      seed: () => ClockIdle(currentTime: DateTime.now(), alarmEnabled: true),
      act: (bloc) => bloc.add(const ClockInRequested()),
      expect: () => [
        isA<ClockActive>()
            .having((s) => s.alarmEnabled, 'alarmEnabled', true)
            .having((s) => s.nextAlarmIn, 'nextAlarmIn', isNotNull),
      ],
    );
  });
}

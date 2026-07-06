import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock_app/domain/entities/active_session.dart';
import 'package:clock_app/domain/entities/user_settings.dart';
import 'package:clock_app/domain/repositories/active_session_repository.dart';
import 'package:clock_app/domain/repositories/user_settings_repository.dart';
import 'package:clock_app/domain/use_cases/clock_in_use_case.dart';
import 'package:clock_app/domain/use_cases/clock_out_use_case.dart';
import 'package:clock_app/features/clock/bloc/clock_bloc.dart';
import 'package:clock_app/core/services/notification_service.dart';

class MockActiveSessionRepository extends Mock implements ActiveSessionRepository {}
class MockUserSettingsRepository extends Mock implements UserSettingsRepository {}
class MockClockInUseCase extends Mock implements ClockInUseCase {}
class MockClockOutUseCase extends Mock implements ClockOutUseCase {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockActiveSessionRepository mockRepository;
  late MockUserSettingsRepository mockSettingsRepository;
  late MockClockInUseCase mockClockIn;
  late MockClockOutUseCase mockClockOut;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockRepository = MockActiveSessionRepository();
    mockSettingsRepository = MockUserSettingsRepository();
    mockClockIn = MockClockInUseCase();
    mockClockOut = MockClockOutUseCase();
    mockNotificationService = MockNotificationService();

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
          scheduledDate:  any(named: 'scheduledDate'),
          delayMinutes:   any(named: 'delayMinutes'),
          alarmEnabled:   any(named: 'alarmEnabled'),
          notificationId: any(named: 'notificationId'),
        )).thenAnswer((_) async => {});
    when(() => mockNotificationService.cancelAllShiftNotifications())
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.alertFiredStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockNotificationService.currentlyRingingId())
        .thenAnswer((_) async => null);
    when(() => mockNotificationService.showAlertFiredNotification(any()))
        .thenAnswer((_) async => {});
  });

  group('ClockBloc', () {
    final tActiveSession = ActiveSession(
      clockedInAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    blocTest<ClockBloc, ClockState>(
      'emits [ClockIdle] when ClockStarted finds no active session',
      build: () {
        when(() => mockRepository.getActiveSession()).thenAnswer((_) async => null);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
        );
      },
      act: (bloc) => bloc.add(const ClockStarted()),
      expect: () => [
        isA<ClockIdle>(),
      ],
    );

    blocTest<ClockBloc, ClockState>(
      'emits [ClockActive] when ClockStarted finds active session',
      build: () {
        when(() => mockRepository.getActiveSession()).thenAnswer((_) async => tActiveSession);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
        );
      },
      act: (bloc) => bloc.add(const ClockStarted()),
      expect: () => [
        isA<ClockActive>(),
      ],
    );

    blocTest<ClockBloc, ClockState>(
      'emits [ClockActive] with alarmEnabled=true when ClockInRequested succeeds and alarm is enabled',
      build: () {
        final session = ActiveSession(
          clockedInAt: DateTime.now(),
          alarmEnabled: true,
        );
        when(() => mockClockIn(alarmEnabled: any(named: 'alarmEnabled')))
            .thenAnswer((_) async => session);
        when(() => mockRepository.getActiveSession()).thenAnswer((_) async => session);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
        );
      },
      seed: () => ClockIdle(currentTime: DateTime.now(), alarmEnabled: true),
      act: (bloc) => bloc.add(const ClockInRequested()),
      expect: () => [
        isA<ClockActive>()
            .having((s) => s.alarmEnabled, 'alarmEnabled', true)
            .having((s) => s.nextAlarmIn, 'nextAlarmIn', isNull),
      ],
    );
  });
}

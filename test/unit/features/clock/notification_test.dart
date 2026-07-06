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
    when(() => mockNotificationService.cancelNotification(any()))
        .thenAnswer((_) async => {});
    when(() => mockNotificationService.alertFiredStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockNotificationService.currentlyRingingId())
        .thenAnswer((_) async => null);

    when(() => mockSettingsRepository.getSettings()).thenAnswer((_) async => const UserSettings(
          accentColorHex: 0xFF4CAF50,
          is12HourFormat: false,
          alarmDelayMinutes: 30,
        ));

    when(() => mockRepository.getActiveSession()).thenAnswer((_) async => ActiveSession(
          clockedInAt: DateTime.now(),
          alarmEnabled: false,
        ));
  });

  group('ClockBloc Notifications', () {
    final tActiveSession = ActiveSession(
      clockedInAt: DateTime.now(),
      alarmEnabled: false,
    );

    blocTest<ClockBloc, ClockState>(
      'schedules notification when ClockInRequested succeeds',
      build: () {
        when(() => mockClockIn()).thenAnswer((_) async => tActiveSession);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
        );
      },
      act: (bloc) => bloc.add(const ClockInRequested()),
      verify: (_) {
        verify(() => mockNotificationService.scheduleShiftEndNotification(
              scheduledDate: any(named: 'scheduledDate'),
              delayMinutes:  any(named: 'delayMinutes'),
              alarmEnabled:  any(named: 'alarmEnabled'),
            )).called(1);
      },
    );

    blocTest<ClockBloc, ClockState>(
      'cancels notification when ClockOutRequested succeeds',
      build: () {
        when(() => mockClockOut()).thenAnswer((_) async => tActiveSession);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
        );
      },
      act: (bloc) => bloc.add(const ClockOutRequested()),
      verify: (_) {
        verify(() => mockNotificationService.cancelAllShiftNotifications()).called(1);
      },
    );

    blocTest<ClockBloc, ClockState>(
      'updates notification when AlarmToggled while clocked in',
      build: () {
        when(() => mockRepository.setAlarmSound(enabled: any(named: 'enabled')))
            .thenAnswer((_) async => {});
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
        );
      },
      seed: () => ClockActive(
        currentTime: DateTime.now(),
        clockedInAt: tActiveSession.clockedInAt,
        remaining: const Duration(minutes: 3),
        alarmEnabled: false,
      ),
      act: (bloc) => bloc.add(const AlarmToggled(enabled: true)),
      verify: (_) {
        verify(() => mockNotificationService.scheduleShiftEndNotification(
              scheduledDate: any(named: 'scheduledDate'),
              delayMinutes:  any(named: 'delayMinutes'),
              alarmEnabled:  any(named: 'alarmEnabled'),
            )).called(1);
      },
    );
  });

  group('ClockBloc Alert Firing', () {
    // Past shift end, so scheduleNextAlarm() lands in the repeat branch.
    final tPastSession = ActiveSession(
      clockedInAt: DateTime.now().subtract(const Duration(minutes: 5)),
      alarmEnabled: true,
    );

    blocTest<ClockBloc, ClockState>(
      'does not cancel other alerts when one fires',
      build: () {
        when(() => mockRepository.getActiveSession()).thenAnswer((_) async => tPastSession);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
        );
      },
      seed: () => ClockActive(
        currentTime: DateTime.now(),
        clockedInAt: tPastSession.clockedInAt,
        remaining: Duration.zero,
        alarmEnabled: true,
      ),
      act: (bloc) => bloc.add(const AlertFired(2)),
      verify: (_) {
        // Regression guard: cancelling an unrelated id here can tear down
        // the native alarm service that's actively ringing the real alert.
        verifyNever(() => mockNotificationService.cancelNotification(any()));
      },
    );

    blocTest<ClockBloc, ClockState>(
      'schedules the next repeat under a different id than the one that fired',
      build: () {
        when(() => mockRepository.getActiveSession()).thenAnswer((_) async => tPastSession);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          settingsRepository: mockSettingsRepository,
          notificationService: mockNotificationService,
        );
      },
      seed: () => ClockActive(
        currentTime: DateTime.now(),
        clockedInAt: tPastSession.clockedInAt,
        remaining: Duration.zero,
        alarmEnabled: true,
      ),
      act: (bloc) => bloc.add(const AlertFired(2)),
      verify: (_) {
        final captured = verify(() => mockNotificationService.scheduleRepeatNotification(
              scheduledDate:  any(named: 'scheduledDate'),
              delayMinutes:   any(named: 'delayMinutes'),
              alarmEnabled:   any(named: 'alarmEnabled'),
              notificationId: captureAny(named: 'notificationId'),
            )).captured;
        expect(captured.single, isIn(NotificationService.repeatPoolId));
        expect(captured.single, isNot(2));
      },
    );

    blocTest<ClockBloc, ClockState>(
      'stopping the alarm cancels it and clears the ringing state',
      build: () => ClockBloc(
        clockIn: mockClockIn,
        clockOut: mockClockOut,
        repository: mockRepository,
        settingsRepository: mockSettingsRepository,
        notificationService: mockNotificationService,
      ),
      seed: () => ClockActive(
        currentTime: DateTime.now(),
        clockedInAt: tPastSession.clockedInAt,
        remaining: Duration.zero,
        alarmEnabled: true,
        isRinging: true,
      ),
      act: (bloc) => bloc.add(const AlarmStopRequested()),
      expect: () => [
        isA<ClockActive>().having((s) => s.isRinging, 'isRinging', false),
      ],
      verify: (_) {
        verify(() => mockNotificationService.cancelNotification(any())).called(1);
      },
    );

    blocTest<ClockBloc, ClockState>(
      'recovers the ringing state on cold start if an alert is already ringing',
      build: () {
        when(() => mockRepository.getActiveSession()).thenAnswer((_) async => tPastSession);
        when(() => mockNotificationService.currentlyRingingId())
            .thenAnswer((_) async => 3);
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
        isA<ClockActive>().having((s) => s.isRinging, 'isRinging', true),
      ],
    );
  });
}

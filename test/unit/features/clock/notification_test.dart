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
import 'package:clock_app/core/services/alarm_service.dart';
import 'package:alarm/model/alarm_settings.dart';

class MockActiveSessionRepository extends Mock implements ActiveSessionRepository {}
class MockUserSettingsRepository extends Mock implements UserSettingsRepository {}
class MockClockInUseCase extends Mock implements ClockInUseCase {}
class MockClockOutUseCase extends Mock implements ClockOutUseCase {}
class MockNotificationService extends Mock implements NotificationService {}
class MockAlarmService extends Mock implements AlarmService {}
class FakeAlarmSettings extends Fake implements AlarmSettings {}

void main() {
  late MockActiveSessionRepository mockRepository;
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
    mockRepository = MockActiveSessionRepository();
    mockSettingsRepository = MockUserSettingsRepository();
    mockClockIn = MockClockInUseCase();
    mockClockOut = MockClockOutUseCase();
    mockNotificationService = MockNotificationService();
    mockAlarmService = MockAlarmService();

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
    when(() => mockNotificationService.actionStream)
        .thenAnswer((_) => const Stream.empty());
    
    when(() => mockAlarmService.ringStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAlarmService.setAlarm(
          id: any(named: 'id'),
          dateTime: any(named: 'dateTime'),
          title: any(named: 'title'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => {});
    when(() => mockAlarmService.stop(any())).thenAnswer((_) async => true);

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
          alarmService: mockAlarmService,
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
          alarmService: mockAlarmService,
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
          alarmService: mockAlarmService,
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
}

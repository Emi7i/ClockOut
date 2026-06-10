import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock_app/domain/entities/clock_entry.dart';
import 'package:clock_app/domain/repositories/clock_repository.dart';
import 'package:clock_app/domain/use_cases/clock_in_use_case.dart';
import 'package:clock_app/domain/use_cases/clock_out_use_case.dart';
import 'package:clock_app/features/clock/bloc/clock_bloc.dart';
import 'package:clock_app/core/services/notification_service.dart';

class MockClockRepository extends Mock implements ClockRepository {}
class MockClockInUseCase extends Mock implements ClockInUseCase {}
class MockClockOutUseCase extends Mock implements ClockOutUseCase {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockClockRepository mockRepository;
  late MockClockInUseCase mockClockIn;
  late MockClockOutUseCase mockClockOut;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockRepository = MockClockRepository();
    mockClockIn = MockClockInUseCase();
    mockClockOut = MockClockOutUseCase();
    mockNotificationService = MockNotificationService();

    // Default mock behaviors
    when(() => mockNotificationService.scheduleShiftEndNotification(
          scheduledDate: any(named: 'scheduledDate'),
          withAlarm: any(named: 'withAlarm'),
        )).thenAnswer((_) async => {});
    when(() => mockNotificationService.cancelAllShiftNotifications())
        .thenAnswer((_) async => {});
  });

  group('ClockBloc Notifications', () {
    final tClockEntry = ClockEntry(
      id: '1',
      clockedInAt: DateTime.now(),
      alarmEnabled: false,
    );

    blocTest<ClockBloc, ClockState>(
      'schedules notification when ClockInRequested succeeds',
      build: () {
        when(() => mockClockIn()).thenAnswer((_) async => tClockEntry);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          notificationService: mockNotificationService,
        );
      },
      act: (bloc) => bloc.add(const ClockInRequested()),
      verify: (_) {
        verify(() => mockNotificationService.scheduleShiftEndNotification(
              scheduledDate: any(named: 'scheduledDate'),
              withAlarm: tClockEntry.alarmEnabled,
            )).called(1);
      },
    );

    blocTest<ClockBloc, ClockState>(
      'cancels notification when ClockOutRequested succeeds',
      build: () {
        when(() => mockClockOut()).thenAnswer((_) async => tClockEntry);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
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
        when(() => mockRepository.setAlarm(enabled: any(named: 'enabled')))
            .thenAnswer((_) async => {});
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
          notificationService: mockNotificationService,
        );
      },
      seed: () => ClockActive(
        currentTime: DateTime.now(),
        clockedInAt: tClockEntry.clockedInAt,
        remaining: const Duration(minutes: 3),
        alarmEnabled: false,
      ),
      act: (bloc) => bloc.add(const AlarmToggled(enabled: true)),
      verify: (_) {
        verify(() => mockNotificationService.scheduleShiftEndNotification(
              scheduledDate: any(named: 'scheduledDate'),
              withAlarm: true,
            )).called(1);
      },
    );
  });
}

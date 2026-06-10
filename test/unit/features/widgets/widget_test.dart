import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock_app/main.dart';
import 'package:clock_app/domain/repositories/clock_repository.dart';
import 'package:clock_app/domain/repositories/log_repository.dart';
import 'package:clock_app/domain/repositories/user_settings_repository.dart';
import 'package:clock_app/domain/use_cases/clock_in_use_case.dart';
import 'package:clock_app/domain/use_cases/clock_out_use_case.dart';
import 'package:clock_app/domain/use_cases/get_logs_use_case.dart';
import 'package:clock_app/domain/entities/user_settings.dart';
import 'package:clock_app/core/services/notification_service.dart';

class MockClockRepository extends Mock implements ClockRepository {}
class MockLogRepository extends Mock implements LogRepository {}
class MockUserSettingsRepository extends Mock implements UserSettingsRepository {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockClockRepository mockClockRepo;
  late MockLogRepository mockLogRepo;
  late MockUserSettingsRepository mockSettingsRepo;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockClockRepo = MockClockRepository();
    mockLogRepo = MockLogRepository();
    mockSettingsRepo = MockUserSettingsRepository();
    mockNotificationService = MockNotificationService();

    // Setup default mock behaviors
    when(() => mockClockRepo.getActiveEntry()).thenAnswer((_) async => null);
    when(() => mockLogRepo.getLogs()).thenAnswer((_) async => []);
    when(() => mockSettingsRepo.getSettings()).thenAnswer((_) async => const UserSettings(
      accentColorHex: 0xFF4CAF50,
      is12HourFormat: false,
      alarmDelayMinutes: 30,
    ));
    when(() => mockNotificationService.initialize()).thenAnswer((_) async => {});
    when(() => mockNotificationService.scheduleShiftEndNotification(
          scheduledDate: any(named: 'scheduledDate'),
          withAlarm: any(named: 'withAlarm'),
        )).thenAnswer((_) async => {});
    when(() => mockNotificationService.cancelAllShiftNotifications())
        .thenAnswer((_) async => {});
  });

  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(ClockApp(
      clockIn: ClockInUseCase(mockClockRepo),
      clockOut: ClockOutUseCase(mockClockRepo),
      getLogs: GetLogsUseCase(mockLogRepo),
      clockRepo: mockClockRepo,
      logRepo: mockLogRepo,
      settingsRepo: mockSettingsRepo,
      notificationService: mockNotificationService,
    ));

    // Initially it shows ClockLoading -> CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    await tester.pump(); // Transition to ClockIdle
    
    expect(find.text('Clock in'), findsOneWidget);
  });
}

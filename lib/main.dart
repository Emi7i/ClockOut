import 'package:alarm/alarm.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_shell.dart';
import 'core/constants/constants.dart';
import 'data/datasources/database_manager.dart';
import 'data/repositories/active_session_repository_impl.dart';
import 'data/repositories/log_repository_impl.dart';
import 'data/repositories/user_settings_repository_impl.dart';
import 'data/services/notification_service_impl.dart';
import 'domain/repositories/active_session_repository.dart';
import 'domain/repositories/log_repository.dart';
import 'domain/repositories/user_settings_repository.dart';
import 'domain/use_cases/clock_in_use_case.dart';
import 'domain/use_cases/clock_out_use_case.dart';
import 'domain/use_cases/get_logs_use_case.dart';
import 'features/clock/bloc/clock_bloc.dart';
import 'features/logs/bloc/logs_bloc.dart';
import 'features/settings/bloc/settings_bloc.dart';
import 'core/services/notification_service.dart';
import 'core/services/alarm_service.dart';

/// ─────────────────────────────────────────────────────────────
///  ENTRY POINT & DEPENDENCY INJECTION
///  Real implementations (SQLite) are now wired up.
///  All BLoCs are created once and provided to the whole tree.
/// ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Setup Builders ────────────────────────────────────
  _setupBuilders();

  // ── Database Manager ───────────────────────────────────
  // (Optional: can also be part of builders if needed)

  // ── Alarm Service ──────────────────────────────────────
  final alarmService = AlarmServiceImpl();
  await alarmService.init();

  // ── Notifications ──────────────────────────────────────
  final notificationService = NotificationServiceImpl(alarmService: alarmService);
  await notificationService.initialize();

  // Register the background-capable action handler
  await AwesomeNotifications().setListeners(
    onActionReceivedMethod: onNotificationActionReceived,
  );

  // ── Repositories (Legacy instantiation for ClockApp, though builders could be used) ───
  final dbManager = DatabaseManager();
  final activeSessionRepo = ActiveSessionRepositoryImpl(dbManager);
  final logRepo           = LogRepositoryImpl(dbManager);
  final settingsRepo      = UserSettingsRepositoryImpl(dbManager);

  // ── Use cases ──────────────────────────────────────────
  final clockIn  = ClockInUseCase(activeSessionRepo);
  final clockOut = ClockOutUseCase(activeSessionRepo);
  final getLogs  = GetLogsUseCase(logRepo);

  runApp(
    ClockApp(
      clockIn:            clockIn,
      clockOut:           clockOut,
      getLogs:            getLogs,
      activeSessionRepo:  activeSessionRepo,
      logRepo:            logRepo,
      settingsRepo:       settingsRepo,
      notificationService: notificationService,
      alarmService:       alarmService,
    ),
  );
}

/// Sets up the domain-layer builders with data-layer implementations.
void _setupBuilders() {
  final dbManager = DatabaseManager();
  
  ActiveSessionRepository.build = () => ActiveSessionRepositoryImpl(dbManager);
  LogRepository.build           = () => LogRepositoryImpl(dbManager);
  UserSettingsRepository.build  = () => UserSettingsRepositoryImpl(dbManager);
}

/// Background entry point for AwesomeNotifications
@pragma('vm:entry-point')
Future<void> onNotificationActionReceived(ReceivedAction receivedAction) async {
  // 1. Setup builders in the new isolate
  _setupBuilders();
  
  // 2. Delegate to the controller in the data layer
  await NotificationController.onActionReceivedMethod(receivedAction);
}

class ClockApp extends StatelessWidget {
  final ClockInUseCase          clockIn;
  final ClockOutUseCase         clockOut;
  final GetLogsUseCase          getLogs;
  final ActiveSessionRepository activeSessionRepo;
  final LogRepository           logRepo;
  final UserSettingsRepository  settingsRepo;
  final NotificationService     notificationService;
  final AlarmService            alarmService;

  const ClockApp({
    super.key,
    required this.clockIn,
    required this.clockOut,
    required this.getLogs,
    required this.activeSessionRepo,
    required this.logRepo,
    required this.settingsRepo,
    required this.notificationService,
    required this.alarmService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ClockBloc(
            clockIn:            clockIn,
            clockOut:           clockOut,
            repository:         activeSessionRepo,
            settingsRepository: settingsRepo,
            notificationService: notificationService,
            alarmService:       alarmService,
          ),
        ),
        BlocProvider(
          create: (_) => LogsBloc(
            getLogs:    getLogs,
            repository: logRepo,
          )..add(const LogsStarted()),
        ),
        BlocProvider(
          create: (_) => SettingsBloc(
            settingsRepo: settingsRepo,
            logRepo:      logRepo,
          )..add(const SettingsStarted()),
        ),
      ],
      child: MaterialApp(
        title:        'Work Clock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.dark(
            primary:   AppColors.accent,
            surface:   AppColors.surface,
          ),
          fontFamily:  'Caveat',
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}

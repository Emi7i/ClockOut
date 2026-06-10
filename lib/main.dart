import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_shell.dart';
import 'core/constants/constants.dart';
import 'data/repositories/clock_repository_impl.dart';
import 'data/repositories/log_repository_impl.dart';
import 'data/repositories/user_settings_repository_impl.dart';
import 'domain/repositories/clock_repository.dart';
import 'domain/repositories/log_repository.dart';
import 'domain/repositories/user_settings_repository.dart';
import 'domain/use_cases/clock_in_use_case.dart';
import 'domain/use_cases/clock_out_use_case.dart';
import 'domain/use_cases/get_logs_use_case.dart';
import 'features/clock/bloc/clock_bloc.dart';
import 'features/logs/bloc/logs_bloc.dart';
import 'features/settings/bloc/settings_bloc.dart';
import 'core/services/notification_service.dart';

/// ─────────────────────────────────────────────────────────────
///  ENTRY POINT & DEPENDENCY INJECTION
///  Real implementations (SQLite) are now wired up.
///  All BLoCs are created once and provided to the whole tree.
/// ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Notifications ──────────────────────────────────────
  final notificationService = NotificationServiceImpl();
  await notificationService.initialize();

  // ── Repositories ───────────────────────────────────────
  final clockRepo    = ClockRepositoryImpl();
  final logRepo      = LogRepositoryImpl();
  final settingsRepo = UserSettingsRepositoryImpl();

  // ── Use cases ──────────────────────────────────────────
  final clockIn  = ClockInUseCase(clockRepo);
  final clockOut = ClockOutUseCase(clockRepo);
  final getLogs  = GetLogsUseCase(logRepo);

  runApp(
    ClockApp(
      clockIn:    clockIn,
      clockOut:   clockOut,
      getLogs:    getLogs,
      clockRepo:  clockRepo,
      logRepo:    logRepo,
      settingsRepo: settingsRepo,
      notificationService: notificationService,
    ),
  );
}

class ClockApp extends StatelessWidget {
  final ClockInUseCase  clockIn;
  final ClockOutUseCase clockOut;
  final GetLogsUseCase  getLogs;
  final ClockRepository clockRepo;
  final LogRepository   logRepo;
  final UserSettingsRepository settingsRepo;
  final NotificationService notificationService;

  const ClockApp({
    super.key,
    required this.clockIn,
    required this.clockOut,
    required this.getLogs,
    required this.clockRepo,
    required this.logRepo,
    required this.settingsRepo,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ClockBloc(
            clockIn:    clockIn,
            clockOut:   clockOut,
            repository: clockRepo,
            notificationService: notificationService,
          )..add(const ClockStarted()),
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
          fontFamily:  'Caveat',          // ← matches AppTextStyles._font
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}

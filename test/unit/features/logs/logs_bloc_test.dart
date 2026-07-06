import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock_app/domain/entities/log_entry.dart';
import 'package:clock_app/domain/repositories/log_repository.dart';
import 'package:clock_app/domain/use_cases/get_logs_use_case.dart';
import 'package:clock_app/features/logs/bloc/logs_bloc.dart';

class MockLogRepository extends Mock implements LogRepository {}
class MockGetLogsUseCase extends Mock implements GetLogsUseCase {}
class FakeLogEntry extends Fake implements LogEntry {}

void main() {
  late MockLogRepository mockRepository;
  late MockGetLogsUseCase mockGetLogs;

  setUpAll(() {
    registerFallbackValue(FakeLogEntry());
  });

  setUp(() {
    mockRepository = MockLogRepository();
    mockGetLogs = MockGetLogsUseCase();
  });

  group('LogsBloc', () {
    final tLogs = [
      LogEntry(
        id: 1,
        date: DateTime.now(),
        bonusTime: Duration.zero,
        userEdited: false,
        clockedInTime: DateTime.now().subtract(const Duration(hours: 8)),
        clockedOutTime: DateTime.now(),
        onlineWork: false,
      ),
    ];

    blocTest<LogsBloc, LogsState>(
      'emits [LogsLoading, LogsLoaded] when LogsStarted succeeds',
      build: () {
        when(() => mockGetLogs()).thenAnswer((_) async => tLogs);
        return LogsBloc(
          getLogs: mockGetLogs,
          repository: mockRepository,
        );
      },
      act: (bloc) => bloc.add(const LogsStarted()),
      expect: () => [
        isA<LogsLoading>(),
        isA<LogsLoaded>().having((s) => s.entries, 'entries', tLogs),
      ],
    );

    blocTest<LogsBloc, LogsState>(
      'emits [LogsLoaded] with empty list and calls repository when LogsDeleteAllRequested',
      build: () {
        when(() => mockRepository.deleteAllLogs()).thenAnswer((_) async => {});
        return LogsBloc(
          getLogs: mockGetLogs,
          repository: mockRepository,
        );
      },
      act: (bloc) => bloc.add(const LogsDeleteAllRequested()),
      expect: () => [
        isA<LogsLoaded>().having((s) => s.entries, 'entries', isEmpty),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteAllLogs()).called(1);
      },
    );

    blocTest<LogsBloc, LogsState>(
      'toggles edit mode on and off',
      build: () {
        when(() => mockGetLogs()).thenAnswer((_) async => tLogs);
        return LogsBloc(
          getLogs: mockGetLogs,
          repository: mockRepository,
        );
      },
      seed: () => const LogsLoaded(entries: [], hoursWorked: 0, hoursTarget: 40),
      act: (bloc) => bloc.add(const LogsEditModeToggled()),
      expect: () => [
        isA<LogsLoaded>().having((s) => s.isEditMode, 'isEditMode', true),
      ],
    );

    blocTest<LogsBloc, LogsState>(
      'switches to monthly stats when the donut chart is tapped',
      build: () => LogsBloc(
        getLogs: mockGetLogs,
        repository: mockRepository,
      ),
      seed: () => const LogsLoaded(
        entries: [],
        hoursWorked: 0,
        hoursTarget: 40,
        isWeeklyView: true,
      ),
      act: (bloc) => bloc.add(const LogsPeriodToggled()),
      expect: () => [
        isA<LogsLoaded>()
            .having((s) => s.isWeeklyView, 'isWeeklyView', false)
            .having((s) => s.hoursTarget, 'hoursTarget', 160),
      ],
    );

    blocTest<LogsBloc, LogsState>(
      'persists an edited entry with userEdited set to true',
      build: () {
        when(() => mockRepository.updateLog(any())).thenAnswer((_) async => {});
        when(() => mockGetLogs()).thenAnswer((_) async => tLogs);
        return LogsBloc(
          getLogs: mockGetLogs,
          repository: mockRepository,
        );
      },
      seed: () => LogsLoaded(entries: tLogs, hoursWorked: 8, hoursTarget: 40, isEditMode: true),
      act: (bloc) => bloc.add(LogEntryEdited(
        original:          tLogs.first,
        newClockedInTime:  DateTime(2026, 1, 1, 9, 0),
        newClockedOutTime: DateTime(2026, 1, 1, 17, 0),
      )),
      verify: (_) {
        final captured = verify(() => mockRepository.updateLog(captureAny())).captured;
        final saved = captured.single as LogEntry;
        expect(saved.userEdited, true);
        expect(saved.clockedInTime, DateTime(2026, 1, 1, 9, 0));
        expect(saved.clockedOutTime, DateTime(2026, 1, 1, 17, 0));
      },
    );
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock_app/domain/entities/log_entry.dart';
import 'package:clock_app/domain/repositories/log_repository.dart';
import 'package:clock_app/domain/use_cases/get_logs_use_case.dart';
import 'package:clock_app/features/logs/bloc/logs_bloc.dart';

class MockLogRepository extends Mock implements LogRepository {}
class MockGetLogsUseCase extends Mock implements GetLogsUseCase {}

void main() {
  late MockLogRepository mockRepository;
  late MockGetLogsUseCase mockGetLogs;

  setUp(() {
    mockRepository = MockLogRepository();
    mockGetLogs = MockGetLogsUseCase();
  });

  group('LogsBloc', () {
    final tLogs = [
      LogEntry(
        date: DateTime.now(),
        status: LogStatus.onTime,
        offset: Duration.zero,
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
  });
}

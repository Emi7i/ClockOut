import 'package:bloc_test/bloc_test.dart';
import 'package:clock_app/domain/entities/log_entry.dart';
import 'package:clock_app/domain/repositories/log_repository.dart';
import 'package:clock_app/domain/use_cases/get_logs_use_case.dart';
import 'package:clock_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:clock_app/features/calendar/cat_assets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetLogsUseCase extends Mock implements GetLogsUseCase {}

class MockLogRepository extends Mock implements LogRepository {}

class FakeLogEntry extends Fake implements LogEntry {}

void main() {
  late MockGetLogsUseCase getLogs;
  late MockLogRepository repository;
  final today = DateTime(2026, 11, 23, 9, 30);

  LogEntry log(DateTime date, int bonusMinutes, {int? id}) => LogEntry(
        id: id,
        date: date,
        bonusTime: Duration(minutes: bonusMinutes),
        userEdited: false,
        onlineWork: false,
      );

  setUpAll(() => registerFallbackValue(FakeLogEntry()));

  setUp(() {
    getLogs = MockGetLogsUseCase();
    repository = MockLogRepository();
  });

  CalendarBloc build() =>
      CalendarBloc(getLogs: getLogs, repository: repository, today: today);

  test('starts on the current month with today selected', () {
    final state = build().state;
    expect(state.visibleMonth, DateTime(2026, 11));
    expect(state.selectedDay, DateTime(2026, 11, 23));
  });

  blocTest<CalendarBloc, CalendarState>(
    'indexes logs by day and picks a cat for each',
    setUp: () => when(() => getLogs()).thenAnswer((_) async => [
          log(DateTime(2026, 11, 20, 15), 30),
          log(DateTime(2026, 11, 21, 8), -10),
          log(DateTime(2026, 11, 22, 17), 0),
        ]),
    build: build,
    act: (bloc) => bloc.add(const CalendarStarted()),
    verify: (bloc) {
      final s = bloc.state;
      expect(s.isLoading, isFalse);
      expect(s.logOn(DateTime(2026, 11, 20)), isNotNull);
      expect(s.catOn(DateTime(2026, 11, 20)), CatAssets.bonusTime);
      expect(s.catOn(DateTime(2026, 11, 21)), CatAssets.earlyLeave);
      expect(s.catOn(DateTime(2026, 11, 22)), CatAssets.worker);
      expect(s.catOn(DateTime(2026, 11, 19)), isNull);
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'month change normalises to the first of the month',
    build: build,
    act: (bloc) => bloc.add(CalendarMonthChanged(DateTime(2026, 12, 15))),
    verify: (bloc) => expect(bloc.state.visibleMonth, DateTime(2026, 12)),
  );

  blocTest<CalendarBloc, CalendarState>(
    'day selection strips the time',
    build: build,
    act: (bloc) => bloc.add(CalendarDaySelected(DateTime(2026, 11, 25, 14))),
    verify: (bloc) => expect(bloc.state.selectedDay, DateTime(2026, 11, 25)),
  );

  blocTest<CalendarBloc, CalendarState>(
    'editing a log saves recomputed bonus time and reloads',
    setUp: () {
      when(() => repository.updateLog(any())).thenAnswer((_) async {});
      when(() => getLogs()).thenAnswer((_) async => []);
    },
    build: build,
    act: (bloc) => bloc.add(CalendarLogEdited(
      original: log(DateTime(2026, 11, 20, 7), 0, id: 4),
      clockedIn: DateTime(2026, 11, 20, 7),
      clockedOut: DateTime(2026, 11, 20, 15, 45), // 45 min over → +30
    )),
    verify: (_) {
      final saved = verify(() => repository.updateLog(captureAny())).captured.single
          as LogEntry;
      expect(saved.id, 4);
      expect(saved.bonusTime, const Duration(minutes: 30));
      expect(saved.userEdited, isTrue);
      verify(() => getLogs()).called(1);
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'deleting a log removes it and reloads',
    setUp: () {
      when(() => repository.deleteLog(any())).thenAnswer((_) async {});
      when(() => getLogs()).thenAnswer((_) async => []);
    },
    build: build,
    act: (bloc) =>
        bloc.add(CalendarLogDeleted(log(DateTime(2026, 11, 20), 0, id: 9))),
    verify: (_) {
      verify(() => repository.deleteLog(9)).called(1);
      verify(() => getLogs()).called(1);
    },
  );
}

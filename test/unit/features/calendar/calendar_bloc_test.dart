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
    'bank balance adds bonus, subtracts early leaves and bank vacations',
    setUp: () => when(() => getLogs()).thenAnswer((_) async => [
          log(DateTime(2026, 11, 20, 15), 120),
          log(DateTime(2026, 11, 21, 8), -30),
          LogEntry.manual(
            type: LogType.vacation,
            day: DateTime(2026, 11, 22),
            shiftDuration: const Duration(hours: 8),
            useBank: true,
          ),
        ]),
    build: build,
    act: (bloc) => bloc.add(const CalendarStarted()),
    verify: (bloc) => expect(
      bloc.state.bankBalance,
      const Duration(hours: -6, minutes: -30),
    ),
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

  LogEntry vacationOn(DateTime day, {int? id}) => LogEntry.manual(
        id: id,
        type: LogType.vacation,
        day: day,
        shiftDuration: const Duration(hours: 8),
      );

  blocTest<CalendarBloc, CalendarState>(
    'adding logs stores each one, reloads once, and selects the first day',
    setUp: () {
      when(() => repository.addLog(any())).thenAnswer((_) async {});
      when(() => getLogs()).thenAnswer((_) async => []);
    },
    build: build,
    act: (bloc) => bloc.add(CalendarLogsAdded([
      vacationOn(DateTime(2026, 11, 26)),
      vacationOn(DateTime(2026, 11, 27)),
      vacationOn(DateTime(2026, 11, 28)),
    ])),
    verify: (bloc) {
      final saved = verify(() => repository.addLog(captureAny())).captured;
      expect(saved, hasLength(3));
      expect((saved.first as LogEntry).type, LogType.vacation);
      expect(bloc.state.selectedDay, DateTime(2026, 11, 26));
      verify(() => getLogs()).called(1);
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'days that already have a log are skipped (one log per day)',
    setUp: () => when(() => getLogs()).thenAnswer((_) async => [
          log(DateTime(2026, 11, 27, 9), 0, id: 1),
        ]),
    build: build,
    act: (bloc) async {
      bloc.add(const CalendarStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      when(() => repository.addLog(any())).thenAnswer((_) async {});
      bloc.add(CalendarLogsAdded([
        vacationOn(DateTime(2026, 11, 26)),
        vacationOn(DateTime(2026, 11, 27)), // taken
        vacationOn(DateTime(2026, 11, 28)),
      ]));
    },
    verify: (_) {
      final saved = verify(() => repository.addLog(captureAny())).captured;
      expect(saved.map((e) => (e as LogEntry).date.day), [26, 28]);
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'adding onto an occupied day alone does nothing',
    setUp: () => when(() => getLogs()).thenAnswer((_) async => [
          log(DateTime(2026, 11, 26, 9), 0, id: 1),
        ]),
    build: build,
    act: (bloc) async {
      bloc.add(const CalendarStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      bloc.add(CalendarLogsAdded([vacationOn(DateTime(2026, 11, 26))]));
    },
    verify: (_) => verifyNever(() => repository.addLog(any())),
  );

  blocTest<CalendarBloc, CalendarState>(
    'updating a log saves it (same id), adds extra days, and reloads once',
    setUp: () {
      when(() => repository.updateLog(any())).thenAnswer((_) async {});
      when(() => repository.addLog(any())).thenAnswer((_) async {});
      when(() => getLogs()).thenAnswer((_) async => []);
    },
    build: build,
    act: (bloc) => bloc.add(CalendarLogUpdated(
      vacationOn(DateTime(2026, 11, 20), id: 4),
      additional: [vacationOn(DateTime(2026, 11, 21))],
    )),
    verify: (bloc) {
      final updated = verify(() => repository.updateLog(captureAny())).captured.single
          as LogEntry;
      expect(updated.id, 4);
      expect(updated.userEdited, isTrue);
      verify(() => repository.addLog(any())).called(1);
      verify(() => getLogs()).called(1);
      expect(bloc.state.selectedDay, DateTime(2026, 11, 20));
    },
  );

  blocTest<CalendarBloc, CalendarState>(
    'a log cannot be moved onto a day owned by another log',
    setUp: () => when(() => getLogs()).thenAnswer((_) async => [
          log(DateTime(2026, 11, 26, 9), 0, id: 1),
        ]),
    build: build,
    act: (bloc) async {
      bloc.add(const CalendarStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      bloc.add(CalendarLogUpdated(vacationOn(DateTime(2026, 11, 26), id: 2)));
    },
    verify: (_) => verifyNever(() => repository.updateLog(any())),
  );

  blocTest<CalendarBloc, CalendarState>(
    'a log can be saved on its own day',
    setUp: () {
      when(() => repository.updateLog(any())).thenAnswer((_) async {});
      when(() => getLogs()).thenAnswer((_) async => [
            log(DateTime(2026, 11, 26, 9), 0, id: 1),
          ]);
    },
    build: build,
    act: (bloc) async {
      bloc.add(const CalendarStarted());
      await bloc.stream.firstWhere((s) => !s.isLoading);
      bloc.add(CalendarLogUpdated(vacationOn(DateTime(2026, 11, 26), id: 1)));
    },
    verify: (_) => verify(() => repository.updateLog(any())).called(1),
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

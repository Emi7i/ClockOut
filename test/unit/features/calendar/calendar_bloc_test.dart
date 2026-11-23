import 'package:bloc_test/bloc_test.dart';
import 'package:clock_app/domain/entities/log_entry.dart';
import 'package:clock_app/domain/use_cases/get_logs_use_case.dart';
import 'package:clock_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetLogsUseCase extends Mock implements GetLogsUseCase {}

void main() {
  late MockGetLogsUseCase getLogs;
  final today = DateTime(2026, 11, 23, 9, 30);

  LogEntry log(DateTime date, int bonusMinutes) => LogEntry(
        date: date,
        bonusTime: Duration(minutes: bonusMinutes),
        userEdited: false,
        onlineWork: false,
      );

  setUp(() => getLogs = MockGetLogsUseCase());

  CalendarBloc build() => CalendarBloc(getLogs: getLogs, today: today);

  test('starts on the current month with today selected', () {
    final state = build().state;
    expect(state.visibleMonth, DateTime(2026, 11));
    expect(state.selectedDay, DateTime(2026, 11, 23));
  });

  blocTest<CalendarBloc, CalendarState>(
    'groups logs by day and exposes per-day status',
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
      expect(s.logsOn(DateTime(2026, 11, 20)), hasLength(1));
      expect(s.statusOn(DateTime(2026, 11, 20)), LogStatus.early);
      expect(s.statusOn(DateTime(2026, 11, 21)), LogStatus.late);
      expect(s.statusOn(DateTime(2026, 11, 22)), LogStatus.onTime);
      expect(s.statusOn(DateTime(2026, 11, 19)), isNull);
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
}

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:clock_app/domain/entities/log_entry.dart';
import 'package:clock_app/domain/repositories/log_repository.dart';
import 'package:clock_app/domain/use_cases/get_logs_use_case.dart';
import 'package:clock_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:clock_app/features/calendar/screens/calendar_screen.dart';
import 'package:clock_app/features/calendar/widgets/calendar_handle.dart';
import 'package:clock_app/features/calendar/widgets/month_pager.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:clock_app/features/settings/bloc/settings_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetLogs extends Mock implements GetLogsUseCase {}

class _MockLogRepository extends Mock implements LogRepository {}

class _FakeLogEntry extends Fake implements LogEntry {}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeLogEntry()));

  late _MockGetLogs getLogs;
  late _MockLogRepository repository;
  late _MockSettingsBloc settingsBloc;

  setUp(() {
    getLogs = _MockGetLogs();
    repository = _MockLogRepository();
    settingsBloc = _MockSettingsBloc();
    when(() => settingsBloc.state).thenReturn(const SettingsLoaded(
      accentColor: Color(0xFF3685DF),
      is12HourFormat: true,
      alarmDelayMinutes: 15,
    ));
    // A log on every weekday of November 2026 so the agenda must scroll.
    when(() => getLogs()).thenAnswer((_) async => [
          for (var d = 1; d <= 30; d++)
            LogEntry(
              date: DateTime(2026, 11, d),
              bonusTime: const Duration(minutes: 30),
              userEdited: false,
              clockedInTime: DateTime(2026, 11, d, 7),
              clockedOutTime: DateTime(2026, 11, d, 15, 30),
              onlineWork: false,
            ),
        ]);
  });

  Future<void> loadRoboto() async {
    // Real font metrics (flutter_test defaults to a wide placeholder font).
    final dir = Platform.environment['FLUTTER_ROOT'] ?? '';
    final loader = FontLoader('Roboto');
    for (final f in ['regular', 'medium', 'bold']) {
      final file = File('$dir/bin/cache/artifacts/material_fonts/roboto-$f.ttf');
      if (!file.existsSync()) return;
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();

    // The month/year title uses the bundled Iceland font.
    final iceland = FontLoader('Iceland')
      ..addFont(Future.value(ByteData.sublistView(
        File('assets/fonts/Iceland-Regular.ttf').readAsBytesSync(),
      )));
    await iceland.load();
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.runAsync(loadRoboto);
    tester.view.physicalSize = const Size(369 * 3, 755 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider(
        create: (_) =>
            CalendarBloc(
              getLogs: getLogs,
              repository: repository,
              today: DateTime(2026, 11, 23),
            )
              ..add(const CalendarStarted()),
          ),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
  }

  double pagerHeight(WidgetTester tester) =>
      tester.getSize(find.byType(MonthPager)).height;

  testWidgets('dragging the handle up condenses the calendar to one week',
      (tester) async {
    await pumpScreen(tester);
    final expanded = pagerHeight(tester);

    await tester.drag(find.byType(CalendarHandle), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(pagerHeight(tester), lessThan(expanded));
    expect(
      pagerHeight(tester),
      MonthPager.weekdayLabelsHeight + MonthPager.rowHeight,
    );

    await tester.drag(find.byType(CalendarHandle), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(pagerHeight(tester), expanded);
  });

  testWidgets('lists days without logs as No event', (tester) async {
    when(() => getLogs()).thenAnswer((_) async => []);
    await pumpScreen(tester);

    // Today's section is shown even though there are no logs at all.
    expect(find.text('Today · Monday, Nov 23'), findsOneWidget);
    expect(find.text('No event'), findsWidgets);
  });

  testWidgets('swiping to another month lists only that month', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Monday, Nov 23', skipOffstage: false), findsNothing); // today has a prefix

    await tester.drag(find.byType(MonthPager), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Tuesday, Dec 1', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Nov', skipOffstage: false), findsNothing);
  });

  testWidgets('a short swipe is enough to change month', (tester) async {
    await pumpScreen(tester);

    // ~25% of the 369px width, well short of the halfway point.
    await tester.drag(find.byType(MonthPager), const Offset(-100, 0));
    await tester.pumpAndSettle();

    expect(find.text('Dec 2026'), findsOneWidget);
  });

  testWidgets('the pen opens the edit dialog and saving updates the log',
      (tester) async {
    when(() => repository.updateLog(any())).thenAnswer((_) async {});
    when(() => getLogs()).thenAnswer((_) async => [
          LogEntry(
            date: DateTime(2026, 11, 23),
            bonusTime: Duration.zero,
            userEdited: false,
            clockedInTime: DateTime(2026, 11, 23, 7),
            clockedOutTime: DateTime(2026, 11, 23, 15),
            onlineWork: false,
          ),
        ]);
    await pumpScreen(tester);

    await tester.tap(find.byType(IconButton).at(1)); // 0 is the header menu
    await tester.pumpAndSettle();
    expect(find.text('Edit log'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    verify(() => repository.updateLog(any())).called(1);
  });

  testWidgets('remote work logs have no edit pen', (tester) async {
    when(() => getLogs()).thenAnswer((_) async => [
          LogEntry(
            date: DateTime(2026, 11, 23),
            bonusTime: Duration.zero,
            userEdited: false,
            onlineWork: true,
          ),
        ]);
    await pumpScreen(tester);

    expect(find.text('Remote work'), findsOneWidget);
    expect(find.byType(IconButton), findsOneWidget); // only the header menu
  });

  testWidgets('tapping a date scrolls the agenda to that date', (tester) async {
    await pumpScreen(tester);
    final scrollable = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    );
    double offset() => tester.state<ScrollableState>(scrollable).position.pixels;

    final before = offset();
    await tester.tap(find.text('3').first); // Nov 3, earlier in the list
    await tester.pumpAndSettle();

    expect(offset(), lessThan(before));
    // The Nov 3 header is now visible in the agenda.
    expect(find.text('Tuesday, Nov 3'), findsOneWidget);
  });
}

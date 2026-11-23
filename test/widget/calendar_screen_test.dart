import 'dart:io';
import 'package:flutter/services.dart';
import 'package:clock_app/domain/entities/log_entry.dart';
import 'package:clock_app/domain/repositories/log_repository.dart';
import 'package:clock_app/domain/use_cases/get_logs_use_case.dart';
import 'package:clock_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:clock_app/features/calendar/screens/calendar_screen.dart';
import 'package:clock_app/features/calendar/widgets/add_log_button.dart';
import 'package:clock_app/features/calendar/widgets/calendar_handle.dart';
import 'package:clock_app/features/calendar/widgets/log_editor_popup.dart';
import 'package:clock_app/features/calendar/widgets/log_type_slider.dart';
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

  group('edit with the same popup', () {
    LogEntry normalLog({int id = 5}) => LogEntry(
          id: id,
          date: DateTime(2026, 11, 23),
          bonusTime: Duration.zero,
          userEdited: false,
          clockedInTime: DateTime(2026, 11, 23, 7),
          clockedOutTime: DateTime(2026, 11, 23, 15),
          onlineWork: false,
        );

    LogEntry vacationLog() => LogEntry(
          id: 6,
          date: DateTime(2026, 11, 23),
          bonusTime: Duration.zero,
          userEdited: true,
          onlineWork: false,
          vacation: true,
        );

    // Pen buttons are IconButtons; index 0 is the header's menu.
    Finder pen() => find.byType(IconButton).at(1);

    setUp(() {
      when(() => repository.updateLog(any())).thenAnswer((_) async {});
      when(() => repository.deleteLog(any())).thenAnswer((_) async {});
    });

    testWidgets('the pen opens the popup prefilled, as "Edit log" with a trash can',
        (tester) async {
      when(() => getLogs()).thenAnswer((_) async => [normalLog()]);
      await pumpScreen(tester);
      expect(find.byTooltip('Delete log'), findsNothing);

      await tester.tap(pen());
      await tester.pumpAndSettle();

      expect(find.text('Edit log'), findsOneWidget);
      expect(find.text('Add log'), findsNothing);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byTooltip('Delete log'), findsOneWidget);
      expect(find.text('7:00 am'), findsOneWidget); // Time enter, prefilled
      expect(find.text('3:00 pm'), findsOneWidget); // Time leave, prefilled
    });

    testWidgets('adding has no trash can', (tester) async {
      when(() => getLogs()).thenAnswer((_) async => []);
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      expect(find.text('Add log'), findsOneWidget);
      expect(find.byTooltip('Delete log'), findsNothing);
    });

    testWidgets('Save updates the same log (same id)', (tester) async {
      when(() => getLogs()).thenAnswer((_) async => [normalLog(id: 5)]);
      await pumpScreen(tester);
      await tester.tap(pen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repository.updateLog(captureAny())).captured.single as LogEntry;
      expect(saved.id, 5);
      expect(find.text('Edit log'), findsNothing);
      verifyNever(() => repository.addLog(any()));
    });

    testWidgets('the trash can deletes the log and closes the popup',
        (tester) async {
      when(() => getLogs()).thenAnswer((_) async => [normalLog(id: 5)]);
      await pumpScreen(tester);
      await tester.tap(pen());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete log'));
      await tester.pumpAndSettle();

      verify(() => repository.deleteLog(5)).called(1);
      expect(find.text('Edit log'), findsNothing);
    });

    testWidgets('every kind of log has an edit pen', (tester) async {
      when(() => getLogs()).thenAnswer((_) async => [vacationLog()]);
      await pumpScreen(tester);

      expect(find.text('Vacation'), findsOneWidget); // the agenda row title
      expect(pen(), findsOneWidget);

      await tester.tap(pen());
      await tester.pumpAndSettle();
      // A vacation opens straight into the From / To range.
      expect(find.text('From:'), findsOneWidget);
      expect(find.text('To:'), findsOneWidget);
    });
  });

  group('popup layout', () {
    setUp(() => when(() => getLogs()).thenAnswer((_) async => []));

    testWidgets('type sits above the date, and the popup is tall enough',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      final typeY = tester.getTopLeft(find.text('Type:')).dy;
      final dateY = tester.getTopLeft(find.textContaining('/ 2026').first).dy;
      expect(typeY, lessThan(dateY));
      expect(LogEditorPopup.height, greaterThan(216)); // more room for the title
    });

    testWidgets('Vacation swaps the date and times for a From / To range',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();
      expect(find.text('Time enter:'), findsOneWidget);
      expect(find.text('From:'), findsNothing);

      await tester.tap(find.text('Vacation'));
      await tester.pumpAndSettle();

      expect(find.text('From:'), findsOneWidget);
      expect(find.text('To:'), findsOneWidget);
      expect(find.text('Time enter:'), findsNothing);
      expect(find.text('Time leave:'), findsNothing);
      // Starts as a single day: the selected one.
      expect(find.text('23 / 11 / 2026'), findsNWidgets(2));

      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();
      expect(find.text('Time enter:'), findsOneWidget);
      expect(find.text('From:'), findsNothing);
    });

    testWidgets('Remote shows only the date, no time fields', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remote'));
      await tester.pumpAndSettle();

      expect(find.text('Date:'), findsOneWidget);
      expect(find.text('Time enter:'), findsNothing);
      expect(find.text('Time leave:'), findsNothing);
      expect(find.text('From:'), findsNothing);
    });

    testWidgets('everything in the popup is centered', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      final popup = tester.getCenter(find.byType(LogEditorPopup)).dx;
      for (final finder in [
        find.text('Add log'),
        find.text('Type:'),
        find.byType(LogTypeSlider),
      ]) {
        expect(tester.getCenter(finder).dx, closeTo(popup, 1), reason: '$finder');
      }
    });
  });

  group('add log button', () {
    double plusTurns(WidgetTester tester) =>
        tester
            .widget<RotationTransition>(find.descendant(
              of: find.byType(AddLogButton),
              matching: find.byType(RotationTransition),
            ))
            .turns
            .value;

    Alignment thumbAlignment(WidgetTester tester) =>
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment
            as Alignment;

    setUp(() {
      when(() => getLogs()).thenAnswer((_) async => []);
      when(() => repository.addLog(any())).thenAnswer((_) async {});
    });

    testWidgets('the plus turns 180° + 45° and the popup opens, then reverses',
        (tester) async {
      await pumpScreen(tester);
      expect(find.text('Add log'), findsNothing);
      expect(plusTurns(tester), 0);

      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();
      expect(find.text('Add log'), findsOneWidget);
      expect(plusTurns(tester), 0.625); // 225°

      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();
      expect(find.text('Add log'), findsNothing);
      expect(plusTurns(tester), 0);
    });

    testWidgets('tapping outside the popup closes it', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(184, 60)); // scrim, above the popup
      await tester.pumpAndSettle();
      expect(find.text('Add log'), findsNothing);
    });

    testWidgets('the slider stops on the keypoint that was tapped',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();
      expect(thumbAlignment(tester), const Alignment(-1, 0)); // Normal

      await tester.tap(find.text('Vacation'));
      await tester.pumpAndSettle();
      expect(thumbAlignment(tester), const Alignment(1, 0));

      await tester.tap(find.text('Remote'));
      await tester.pumpAndSettle();
      expect(thumbAlignment(tester), const Alignment(0, 0));

      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();
      expect(thumbAlignment(tester), const Alignment(-1, 0));
    });

    testWidgets('dragging the slider snaps to a keypoint, never between',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(LogTypeSlider), const Offset(160, 0));
      await tester.pumpAndSettle();
      expect(thumbAlignment(tester), const Alignment(1, 0));
    });

    testWidgets('Add is disabled until a normal log has both times',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      verifyNever(() => repository.addLog(any()));
      expect(find.text('Add log'), findsOneWidget); // still open
    });

    testWidgets('adding a vacation day saves it and closes the popup',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vacation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repository.addLog(captureAny())).captured.single as LogEntry;
      expect(saved.type, LogType.vacation);
      expect(saved.date, DateTime(2026, 11, 23));
      expect(find.text('Add log'), findsNothing);
    });

    testWidgets('"Use time from bank" saves the vacation as paid from the bank',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vacation'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use time from bank'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repository.addLog(captureAny())).captured.single as LogEntry;
      expect(saved.usedBank, isTrue);
      expect(saved.bonusTime, const Duration(hours: -8));
    });

    testWidgets('the bank toggle is only offered for vacation', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();
      expect(find.text('Use time from bank'), findsNothing);

      await tester.tap(find.text('Vacation'));
      await tester.pumpAndSettle();
      expect(find.text('Use time from bank'), findsOneWidget);
    });

    testWidgets('a bank vacation says "Used time from bank" in the agenda',
        (tester) async {
      when(() => getLogs()).thenAnswer((_) async => [
            LogEntry.manual(
              type: LogType.vacation,
              day: DateTime(2026, 11, 23),
              shiftDuration: const Duration(hours: 8),
              useBank: true,
            ),
          ]);
      await pumpScreen(tester);

      expect(find.text('Used time from bank'), findsOneWidget);
    });

    testWidgets('editing a bank vacation shows the toggle already on',
        (tester) async {
      when(() => getLogs()).thenAnswer((_) async => [
            LogEntry.manual(
              id: 1,
              type: LogType.vacation,
              day: DateTime(2026, 11, 23),
              shiftDuration: const Duration(hours: 8),
              useBank: true,
            ),
          ]);
      when(() => repository.updateLog(any())).thenAnswer((_) async {});
      await pumpScreen(tester);
      // Pens are IconButtons; index 0 is the header's menu.
      await tester.tap(find.byType(IconButton).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Use time from bank'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repository.updateLog(captureAny())).captured.single as LogEntry;
      expect(saved.usedBank, isTrue);
    });

    testWidgets('Cancel closes without saving', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add log'), findsNothing);
      verifyNever(() => repository.addLog(any()));
    });

    testWidgets('a day that already has a log cannot get a second one',
        (tester) async {
      when(() => getLogs()).thenAnswer((_) async => [
            LogEntry(
              date: DateTime(2026, 11, 23),
              bonusTime: Duration.zero,
              userEdited: false,
              onlineWork: true,
            ),
          ]);
      await pumpScreen(tester);
      await tester.tap(find.byType(AddLogButton));
      await tester.pumpAndSettle();

      expect(find.text('A log already exists for this day'), findsOneWidget);
      await tester.tap(find.text('Vacation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      verifyNever(() => repository.addLog(any()));
    });
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

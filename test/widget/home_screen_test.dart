import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:clock_app/features/clock/bloc/clock_bloc.dart';
import 'package:clock_app/features/clock/screens/home_screen.dart';
import 'package:clock_app/features/settings/bloc/settings_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockClockBloc extends MockBloc<ClockEvent, ClockState>
    implements ClockBloc {}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  setUpAll(() => registerFallbackValue(const ClockOutRequested()));

  late _MockClockBloc clockBloc;
  late _MockSettingsBloc settingsBloc;
  late StreamController<ClockState> states;
  late ClockState current;

  final startShift = find.text('Start\nShift');

  ClockState idle() => ClockIdle(currentTime: DateTime(2026, 11, 24, 9));
  ClockState active(DateTime since) => ClockActive(
        currentTime: DateTime.now(),
        clockedInAt: since,
        remaining: const Duration(hours: 8),
      );

  void emit(ClockState s) {
    current = s;
    states.add(s);
  }

  setUp(() {
    clockBloc = _MockClockBloc();
    settingsBloc = _MockSettingsBloc();
    states = StreamController<ClockState>.broadcast();
    addTearDown(states.close);
    current = idle();
    when(() => clockBloc.state).thenAnswer((_) => current);
    when(() => clockBloc.stream).thenAnswer((_) => states.stream);
    when(() => settingsBloc.state).thenReturn(const SettingsLoaded(
      accentColor: Color(0xFF3685DF),
      is12HourFormat: true,
      alarmDelayMinutes: 15,
    ));
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.runAsync(() async {
      final dir = Platform.environment['FLUTTER_ROOT'] ?? '';
      final roboto = FontLoader('Roboto');
      for (final f in ['regular', 'medium', 'bold']) {
        final file =
            File('$dir/bin/cache/artifacts/material_fonts/roboto-$f.ttf');
        if (!file.existsSync()) return;
        roboto.addFont(
            Future.value(ByteData.sublistView(file.readAsBytesSync())));
      }
      await roboto.load();
      final iceland = FontLoader('Iceland')
        ..addFont(Future.value(ByteData.sublistView(
            File('assets/fonts/Iceland-Regular.ttf').readAsBytesSync())));
      await iceland.load();
    });
    tester.view.physicalSize = const Size(388 * 2, 764 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ClockBloc>.value(value: clockBloc),
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
        ],
        child: HomeScreen(onSettingsTap: () {}, onCalendarTap: () {}),
      ),
    ));
    await tester.pump();
  }

  /// The ring keeps turning forever, so pumpAndSettle would never return.
  Future<void> play(WidgetTester t, Duration total) async {
    const step = Duration(milliseconds: 50);
    for (var d = Duration.zero; d < total; d += step) {
      await t.pump(step);
    }
  }

  testWidgets('idle: the Start Shift card is shown', (t) async {
    await pumpHome(t);
    expect(startShift, findsOneWidget);
  });

  testWidgets('tapping Start Shift clocks in and plays the 3 s intro once',
      (t) async {
    await pumpHome(t);
    await t.tap(startShift);
    await t.pump();
    verify(() => clockBloc.add(any(that: isA<ClockInRequested>())))
        .called(1);

    emit(active(DateTime.now()));
    await play(t, const Duration(seconds: 1));
    expect(startShift, findsNothing); // the card collapses almost at once
    await play(t, const Duration(seconds: 3));
    expect(startShift, findsNothing); // and stays away while the shift runs
  });

  testWidgets('reopening with a shift running skips the intro', (t) async {
    current = active(DateTime.now().subtract(const Duration(hours: 3)));
    await pumpHome(t);
    expect(startShift, findsNothing);
    // No debug controls leak into release, but they exist in tests (debug).
    expect(find.text('Clock out (debug)'), findsOneWidget);
  });

  testWidgets('clock-out: the UFO laps out of sight, then the card returns',
      (t) async {
    current = active(DateTime.now().subtract(const Duration(hours: 8)));
    await pumpHome(t);
    expect(startShift, findsNothing);

    emit(idle());
    await t.pump();
    // During the lap (1.3 s from the right end) the card is still away.
    await play(t, const Duration(milliseconds: 1000));
    expect(startShift, findsNothing);
    // Lap (1.3 s) + intro in reverse (3 s) + margin.
    await play(t, const Duration(milliseconds: 3500));
    expect(startShift, findsOneWidget);
  });

  testWidgets('clock-out during the intro just runs the intro back',
      (t) async {
    await pumpHome(t);
    await t.tap(startShift);
    emit(active(DateTime.now()));
    await play(t, const Duration(milliseconds: 1200));
    emit(idle());
    await play(t, const Duration(seconds: 4));
    expect(startShift, findsOneWidget);
  });

  testWidgets('the card cannot be tapped again while the sequence runs',
      (t) async {
    current = active(DateTime.now().subtract(const Duration(hours: 8)));
    await pumpHome(t);
    emit(idle());
    await play(t, const Duration(seconds: 1));
    // No card on screen to tap during the lap.
    expect(startShift, findsNothing);
    verifyNever(() => clockBloc.add(any(that: isA<ClockInRequested>())));
  });
}

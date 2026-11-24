import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:clock_app/domain/tracks/bonus_track.dart';
import 'package:clock_app/domain/tracks/remote_track.dart';
import 'package:clock_app/domain/tracks/vacation_track.dart';
import 'package:clock_app/features/clock/bloc/clock_bloc.dart';
import 'package:clock_app/features/clock/fake_track_stats.dart';
import 'package:clock_app/features/clock/screens/home_screen.dart';
import 'package:clock_app/features/clock/widgets/scene/night_readout.dart';
import 'package:clock_app/features/clock/widgets/scene/night_track_values.dart';
import 'package:clock_app/features/clock/widgets/scene/night_tracks.dart';
import 'package:clock_app/features/settings/bloc/settings_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockClockBloc extends MockBloc<ClockEvent, ClockState>
    implements ClockBloc {}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

Future<void> _loadFonts(WidgetTester tester) async {
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
}

NightTrackValues stats({
  Duration bank = const Duration(hours: 11),
  int used = 8,
  int converted = 0,
  bool remoteAvailable = true,
}) =>
    NightTrackValues(
      vacation: vacationStatus(usedDays: used, convertedDays: converted),
      remote: RemoteStatus(available: remoteAvailable),
      bonus: bonusStatus(bank),
    );

Finder body(NightBody b) => find.byKey(ValueKey('night-body-${b.name}'));

void main() {
  group('Night bodies and readout', () {
    late ValueNotifier<NightBody> selected;
    var converts = 0;

    Future<void> pumpNight(
      WidgetTester tester,
      NightTrackValues values, {
      double scene = 1,
    }) async {
      await _loadFonts(tester);
      tester.view.physicalSize = const Size(388 * 2, 764 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      selected = ValueNotifier<NightBody>(NightBody.bonus);
      addTearDown(selected.dispose);
      converts = 0;
      final sceneAnim = AlwaysStoppedAnimation<double>(scene);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stack(children: [
            Positioned.fill(
              child: NightTracks(
                scene: sceneAnim,
                values: values,
                selected: selected,
                onSelect: (b) => selected.value = b,
              ),
            ),
            Positioned.fill(
              child: NightReadout(
                scene: sceneAnim,
                values: values,
                selected: selected,
                onConvert: () => converts++,
              ),
            ),
          ]),
        ),
      ));
      await tester.pump();
    }

    testWidgets('each body has a short label under it', (t) async {
      await pumpNight(t, stats());
      expect(find.text('Vacation'), findsOneWidget);
      expect(find.text('Remote'), findsOneWidget);
      expect(find.text('Bonus'), findsOneWidget);
    });

    testWidgets('Bonus is selected by default and shown in the readout',
        (t) async {
      await pumpNight(t, stats(bank: const Duration(hours: 11)));
      expect(selected.value, NightBody.bonus);
      expect(find.text('BONUS'), findsOneWidget);
      expect(find.text('11h = 1 day ready + 3h'), findsOneWidget);
    });

    testWidgets('tapping a body selects it and shows its value', (t) async {
      await pumpNight(t, stats(used: 8));

      await t.tap(body(NightBody.vacation));
      await t.pumpAndSettle();
      expect(selected.value, NightBody.vacation);
      expect(find.text('VACATION'), findsOneWidget);
      expect(find.text('14 of 22 left'), findsOneWidget);

      await t.tap(body(NightBody.remote));
      await t.pumpAndSettle();
      expect(selected.value, NightBody.remote);
      expect(find.text('1 left this week'), findsOneWidget);

      await t.tap(body(NightBody.bonus));
      await t.pumpAndSettle();
      expect(selected.value, NightBody.bonus);
    });

    testWidgets('a used remote day reads 0 left this week', (t) async {
      await pumpNight(t, stats(remoteAvailable: false));
      await t.tap(body(NightBody.remote));
      await t.pumpAndSettle();
      expect(find.text('0 left this week'), findsOneWidget);
    });

    testWidgets('every body has a tap target of at least 48 px', (t) async {
      await pumpNight(t, stats());
      for (final b in NightBody.values) {
        final size = t.getSize(body(b));
        expect(size.width, greaterThanOrEqualTo(48), reason: b.name);
        expect(size.height, greaterThanOrEqualTo(48), reason: b.name);
      }
    });

    testWidgets('only the selected body has its ring showing', (t) async {
      await pumpNight(t, stats());
      double ringOpacity() => t
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .where((w) => w.child is DecoratedBox)
          .map((w) => w.opacity)
          .fold(0.0, (a, b) => a + b);
      expect(ringOpacity(), 1);
      await t.tap(body(NightBody.vacation));
      await t.pumpAndSettle();
      expect(ringOpacity(), 1); // still exactly one ring
    });

    testWidgets('Convert shows only for Bonus', (t) async {
      await pumpNight(t, stats());
      expect(find.text('Convert'), findsOneWidget);
      await t.tap(body(NightBody.vacation));
      await t.pumpAndSettle();
      expect(find.text('Convert'), findsNothing);
      await t.tap(body(NightBody.bonus));
      await t.pumpAndSettle();
      expect(find.text('Convert'), findsOneWidget);
    });

    testWidgets('Convert is enabled from 8 h and reports a tap', (t) async {
      await pumpNight(t, stats(bank: const Duration(hours: 8)));
      await t.tap(find.text('Convert'));
      expect(converts, 1);
    });

    testWidgets('Convert is disabled below 8 h', (t) async {
      await pumpNight(
          t, stats(bank: const Duration(hours: 7, minutes: 59)));
      expect(find.text('Convert'), findsOneWidget);
      await t.tap(find.text('Convert'));
      expect(converts, 0);
    });

    testWidgets('nothing reacts before the Night scene is shown', (t) async {
      await pumpNight(t, stats(), scene: 0);
      expect(find.text('Vacation'), findsNothing);
      expect(find.text('BONUS'), findsNothing);
    });

    testWidgets('while fading in, taps are ignored', (t) async {
      await pumpNight(t, stats(), scene: 0.65);
      await t.tap(body(NightBody.vacation), warnIfMissed: false);
      expect(selected.value, NightBody.bonus);
    });

    testWidgets('the total bonus hours earned is not on this screen',
        (t) async {
      await pumpNight(t, stats(bank: const Duration(hours: 11)));
      expect(find.textContaining('earned'), findsNothing);
      expect(find.textContaining('total'), findsNothing);
    });
  });

  group('Convert flow on the home screen', () {
    late _MockClockBloc clockBloc;
    late _MockSettingsBloc settingsBloc;
    late Duration savedBank;
    late int savedConverted;

    setUp(() {
      savedBank = FakeTrackStats.bonusBalance;
      savedConverted = FakeTrackStats.vacationConvertedDays;
      FakeTrackStats.bonusBalance = const Duration(hours: 11);
      FakeTrackStats.vacationConvertedDays = 0;
      FakeTrackStats.vacationUsedDays = 8;

      clockBloc = _MockClockBloc();
      settingsBloc = _MockSettingsBloc();
      when(() => clockBloc.state)
          .thenReturn(ClockIdle(currentTime: DateTime(2026, 11, 24, 9)));
      when(() => clockBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => settingsBloc.state).thenReturn(const SettingsLoaded(
        accentColor: Color(0xFF3685DF),
        is12HourFormat: true,
        alarmDelayMinutes: 15,
      ));
    });

    tearDown(() {
      FakeTrackStats.bonusBalance = savedBank;
      FakeTrackStats.vacationConvertedDays = savedConverted;
    });

    Future<void> openNight(WidgetTester tester) async {
        await _loadFonts(tester);
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
      // Swipe up: Day -> Night (about 1.4 s).
      final g = await tester.startGesture(const Offset(300, 400));
      await g.moveBy(const Offset(0, -30));
      await g.moveBy(const Offset(0, -100));
      await g.up();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('Convert asks first; Cancel changes nothing', (t) async {
      await openNight(t);
      expect(find.text('11h = 1 day ready + 3h'), findsOneWidget);

      await t.tap(find.text('Convert'));
      await t.pump(const Duration(milliseconds: 400)); // dialog opens
      expect(find.text('Convert 8 h into 1 vacation day?'), findsOneWidget);
      expect(find.textContaining('11h → 3h'), findsOneWidget);
      expect(find.textContaining('22 → 23'), findsOneWidget);

      await t.tap(find.text('Cancel'));
      await t.pump(const Duration(milliseconds: 400));
      expect(FakeTrackStats.bonusBalance, const Duration(hours: 11));
      expect(FakeTrackStats.vacationConvertedDays, 0);
      expect(find.text('11h = 1 day ready + 3h'), findsOneWidget);
    });

    testWidgets('confirming converts 8 h into 1 vacation day', (t) async {
      await openNight(t);
      await t.tap(find.text('Convert'));
      await t.pump(const Duration(milliseconds: 400));

      // The dialog's own "Convert" is the second one on screen.
      await t.tap(find.text('Convert').last);
      await t.pump(const Duration(milliseconds: 400));

      expect(FakeTrackStats.bonusBalance, const Duration(hours: 3));
      expect(FakeTrackStats.vacationConvertedDays, 1);
      // The readout redraws with the new bank; 3 h is below a day.
      expect(find.text('3h · 5h to the next day'), findsOneWidget);
      // ... and the vacation total now has the extra day.
      await t.tap(body(NightBody.vacation));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('15 of 23 left'), findsOneWidget);
    });
  });
}

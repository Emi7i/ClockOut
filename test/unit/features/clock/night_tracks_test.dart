import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/features/clock/fake_track_stats.dart';
import 'package:clock_app/features/clock/widgets/scene/orbit_paths.dart';

Offset pointAt(OrbitCurve c, double fraction) {
  final m = c.toPath(1).computeMetrics().first;
  return m.getTangentForOffset(m.length * fraction)!.position;
}

void main() {
  group('orbit paths match the Figma joints (solid meets dashed)', () {
    // Figma "Paths" frame: joint points, in design pixels.
    test('top orbit', () {
      final p = pointAt(OrbitCurves.top, OrbitCurves.topFigma);
      expect((p - const Offset(205.5, 145.744)).distance, lessThan(1.5));
    });
    test('middle orbit', () {
      final p = pointAt(OrbitCurves.middle, OrbitCurves.middleFigma);
      expect((p - const Offset(269.658, 282.917)).distance, lessThan(1.5));
    });
    test('bottom orbit', () {
      final p = pointAt(OrbitCurves.bottom, OrbitCurves.bottomFigma);
      expect((p - const Offset(113.945, 410.368)).distance, lessThan(1.5));
    });
  });

  test('the orbits scale with the screen', () {
    final one = OrbitCurves.top.toPath(1).computeMetrics().first.length;
    final two = OrbitCurves.top.toPath(2).computeMetrics().first.length;
    expect(two, closeTo(one * 2, one * 0.005)); // metric flattening tolerance
  });

  group('padding keeps the bodies on screen', () {
    test('a stat of 0 is the padding from the start, 1 the same from the end',
        () {
      expect(trackFraction(0), OrbitCurves.trackPadding);
      expect(trackFraction(1), 1 - OrbitCurves.trackPadding);
      expect(trackFraction(0.5), 0.5);
    });

    test('the padding is 1 h of the 8 h bonus track', () {
      expect(OrbitCurves.trackPadding, 1 / 8);
    });

    test('is monotonic and clamps stats outside 0..1', () {
      var last = -1.0;
      for (var i = 0; i <= 20; i++) {
        final f = trackFraction(i / 20);
        expect(f, greaterThan(last));
        last = f;
      }
      expect(trackFraction(-1), trackFraction(0));
      expect(trackFraction(2), trackFraction(1));
    });

    test('at both ends every body is well inside the screen', () {
      for (final curve in [
        OrbitCurves.top,
        OrbitCurves.middle,
        OrbitCurves.bottom,
      ]) {
        for (final stat in [0.0, 1.0]) {
          final p = pointAt(curve, trackFraction(stat));
          expect(p.dx, inInclusiveRange(30, 388 - 30),
              reason: 'stat $stat on an orbit starting at ${curve.start}');
        }
      }
    });

    test('a custom padding is honoured', () {
      expect(trackFraction(0, padding: 0), 0);
      expect(trackFraction(1, padding: 0), 1);
      expect(trackFraction(0.5, padding: 0.2), 0.5);
      expect(trackFraction(1, padding: 0.2), closeTo(0.8, 1e-12));
    });
  });

  group('fake stats', () {
    final now = DateTime(2026, 11, 24); // a Tuesday

    test('always give valid positions, whatever values are in the file', () {
      final v = fakeNightTrackValues(now);
      for (final x in [v.vacation, v.remote, v.bonus]) {
        expect(x, inInclusiveRange(0, 1));
      }
    });

    test('changing the remote fake value moves its body', () {
      final saved = List<DateTime>.of(FakeTrackStats.remoteDays);
      addTearDown(() {
        FakeTrackStats.remoteDays
          ..clear()
          ..addAll(saved);
      });

      FakeTrackStats.remoteDays.clear();
      final before = fakeNightTrackValues(now);
      expect(before.remote, 0); // still available: start of the orbit

      FakeTrackStats.remoteDays.add(DateTime(2026, 11, 23));
      final after = fakeNightTrackValues(now);
      expect(after.remote, 1); // used: end of the orbit
      // The other two are untouched.
      expect(after.vacation, before.vacation);
      expect(after.bonus, before.bonus);

      // Next week it is available again, back at the start.
      expect(fakeNightTrackValues(DateTime(2026, 11, 29)).remote, 0);
    });
  });
}

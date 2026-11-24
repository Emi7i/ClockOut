import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/features/clock/widgets/scene/shift_clock.dart';

void main() {
  final start = DateTime(2026, 11, 24, 9);

  double at(Duration d, {double scale = 1, Duration offset = Duration.zero}) =>
      shiftOrbitFraction(
        clockedInAt: start,
        now: start.add(d),
        timeScale: scale,
        startOffset: offset,
      );

  test('0 at clock-in, 0.5 at 4 h, 1 at exactly 8 h', () {
    expect(at(Duration.zero), 0);
    expect(at(const Duration(hours: 4)), 0.5);
    expect(at(const Duration(hours: 8)), 1);
  });

  test('parks at the right end after 8 h until clock-out', () {
    expect(at(const Duration(hours: 9)), 1);
    expect(at(const Duration(days: 2)), 1);
  });

  test('a clock set back before the start never goes negative', () {
    expect(at(const Duration(minutes: -5)), 0);
  });

  test('position depends only on the clock, not on how often it is asked', () {
    expect(at(const Duration(hours: 2)), at(const Duration(hours: 2)));
    expect(at(const Duration(hours: 2)), 0.25);
  });

  test('debug scale: 8 h in 30 s', () {
    const scale = 8 * 3600 / 30;
    expect(at(const Duration(seconds: 15), scale: scale), closeTo(0.5, 1e-9));
    expect(at(const Duration(seconds: 30), scale: scale), closeTo(1, 1e-9));
  });

  test('debug start offset removes the jump at the intro hand-over', () {
    const scale = 8 * 3600 / 30;
    const intro = Duration(seconds: 3);
    expect(at(intro, scale: scale, offset: intro), 0);
  });
}

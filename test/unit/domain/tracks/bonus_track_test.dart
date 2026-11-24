import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/domain/tracks/bonus_track.dart';

void main() {
  BonusStatus at(Duration d) => bonusStatus(d);

  test('0 h: at the start, nothing ready', () {
    final s = at(Duration.zero);
    expect(s.progress, 0);
    expect(s.daysReady, 0);
    expect(s.remainder, Duration.zero);
  });

  test('progress is (balance mod 8 h) / 8 h', () {
    expect(at(const Duration(hours: 2)).progress, 0.25);
    expect(at(const Duration(hours: 4)).progress, 0.5);
    expect(at(const Duration(hours: 6)).progress, 0.75);
    expect(at(const Duration(hours: 2, minutes: 30)).progress,
        closeTo(2.5 / 8, 1e-12));
  });

  test('exactly 8 h: stays at the end of the track, 1 day ready', () {
    final s = at(const Duration(hours: 8));
    expect(s.progress, 1);
    expect(s.daysReady, 1);
    expect(s.remainder, Duration.zero);
  });

  test('just under 8 h: nearly full, no day ready yet', () {
    final s = at(const Duration(hours: 7, minutes: 59));
    expect(s.progress, closeTo(479 / 480, 1e-12));
    expect(s.daysReady, 0);
  });

  test('just over 8 h: wraps to the start with the day ready', () {
    final s = at(const Duration(hours: 8, minutes: 1));
    expect(s.progress, closeTo(1 / 480, 1e-12));
    expect(s.daysReady, 1);
    expect(s.remainder, const Duration(minutes: 1));
  });

  test('11 h = 1 day ready + 3 h', () {
    final s = at(const Duration(hours: 11));
    expect(s.daysReady, 1);
    expect(s.remainder, const Duration(hours: 3));
    expect(s.progress, 3 / 8);
  });

  test('wraps again after every 8 h, and stays full on each exact multiple',
      () {
    final s16 = at(const Duration(hours: 16));
    expect(s16.progress, 1);
    expect(s16.daysReady, 2);
    final s19 = at(const Duration(hours: 19));
    expect(s19.daysReady, 2);
    expect(s19.progress, 3 / 8);
  });

  test('an overdrawn bank sits at the start with nothing ready', () {
    final s = at(const Duration(hours: -3));
    expect(s.progress, 0);
    expect(s.daysReady, 0);
    expect(s.remainder, const Duration(hours: -3));
  });

  test('the conversion rate can be overridden', () {
    final s = bonusStatus(const Duration(hours: 5), perDay: const Duration(hours: 10));
    expect(s.progress, 0.5);
  });
}

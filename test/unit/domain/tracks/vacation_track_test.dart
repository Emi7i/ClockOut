import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/domain/tracks/vacation_track.dart';

void main() {
  test('a fresh year: all 22 days left, the comet at the start', () {
    final s = vacationStatus(usedDays: 0, convertedDays: 0);
    expect(s.daysAvailable, 22);
    expect(s.daysLeft, 22);
    expect(s.progress, 0);
  });

  test('progress = the share used = 1 - days left / days available', () {
    final s = vacationStatus(usedDays: 8, convertedDays: 0);
    expect(s.daysLeft, 14);
    expect(s.progress, closeTo(1 - 14 / 22, 1e-12));
    expect(s.progress, closeTo(8 / 22, 1e-12));
  });

  test('converted days raise both the days available and the days left', () {
    final s = vacationStatus(usedDays: 8, convertedDays: 3);
    expect(s.daysAvailable, 25);
    expect(s.daysLeft, 17);
    expect(s.progress, closeTo(1 - 17 / 25, 1e-12));
  });

  test('converting a day moves the comet back a little (more is left)', () {
    final before = vacationStatus(usedDays: 8, convertedDays: 0).progress;
    final after = vacationStatus(usedDays: 8, convertedDays: 1).progress;
    expect(after, lessThan(before));
  });

  test('every day used: the comet is at the end', () {
    expect(vacationStatus(usedDays: 22, convertedDays: 0).progress, 1);
    expect(vacationStatus(usedDays: 25, convertedDays: 3).progress, 1);
  });

  test('22 used with one converted day is just short of the end', () {
    final s = vacationStatus(usedDays: 22, convertedDays: 1);
    expect(s.daysLeft, 1);
    expect(s.progress, closeTo(22 / 23, 1e-12));
  });

  test('taking more days than available never goes past the end', () {
    final s = vacationStatus(usedDays: 30, convertedDays: 0);
    expect(s.daysLeft, 0);
    expect(s.progress, 1);
  });

  test('the allowance can be overridden', () {
    final s = vacationStatus(usedDays: 5, convertedDays: 0, annualDays: 25);
    expect(s.daysAvailable, 25);
    expect(s.progress, closeTo(5 / 25, 1e-12));
  });
}

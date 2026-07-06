import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/domain/entities/log_entry.dart';

void main() {
  group('LogEntry.computeBonusTime', () {
    final clockedInAt = DateTime(2026, 1, 1, 9, 0);
    const shiftDuration = Duration(hours: 8);
    final shiftEnd = clockedInAt.add(shiftDuration); // 17:00

    Duration bonusFor(DateTime clockedOutAt) => LogEntry.computeBonusTime(
          clockedInAt:  clockedInAt,
          clockedOutAt: clockedOutAt,
          shiftDuration: shiftDuration,
        );

    test('clocking out exactly at shift end is on time', () {
      expect(bonusFor(shiftEnd), Duration.zero);
    });

    test('clocking out under 30 minutes after shift end is still on time', () {
      expect(bonusFor(shiftEnd.add(const Duration(minutes: 29))), Duration.zero);
    });

    test('clocking out 30 minutes after shift end reads as a 30 minute bonus', () {
      expect(bonusFor(shiftEnd.add(const Duration(minutes: 30))), const Duration(minutes: 30));
    });

    test('clocking out 55 minutes after shift end still only reads +30', () {
      expect(bonusFor(shiftEnd.add(const Duration(minutes: 55))), const Duration(minutes: 30));
    });

    test('clocking out 60 minutes after shift end reads as a 60 minute bonus', () {
      expect(bonusFor(shiftEnd.add(const Duration(minutes: 60))), const Duration(minutes: 60));
    });

    test('clocking out before shift end is an exact, unrounded deficit', () {
      expect(bonusFor(shiftEnd.subtract(const Duration(minutes: 5))), const Duration(minutes: -5));
    });
  });

  group('LogEntry.offsetLabel', () {
    LogEntry entryWithBonus(Duration bonusTime) => LogEntry(
          date: DateTime(2026, 1, 1),
          bonusTime: bonusTime,
          userEdited: false,
          onlineWork: false,
        );

    test('shows "On Time" when there is no bonus/deficit', () {
      expect(entryWithBonus(Duration.zero).offsetLabel, 'On Time');
    });

    test('shows a plain +N for bonus time', () {
      expect(entryWithBonus(const Duration(minutes: 30)).offsetLabel, '+30');
    });

    test('shows -N minutes for an early clock-out', () {
      expect(entryWithBonus(const Duration(minutes: -5)).offsetLabel, '-5 minutes');
    });

    test('converts a bonus of an hour or more to Xh / Xh Ym', () {
      expect(entryWithBonus(const Duration(minutes: 60)).offsetLabel, '+1h');
      expect(entryWithBonus(const Duration(minutes: 90)).offsetLabel, '+1h 30m');
      expect(entryWithBonus(const Duration(minutes: 150)).offsetLabel, '+2h 30m');
    });

    test('converts an early clock-out of an hour or more to Xh / Xh Ym', () {
      expect(entryWithBonus(const Duration(minutes: -60)).offsetLabel, '-1h');
      expect(entryWithBonus(const Duration(minutes: -75)).offsetLabel, '-1h 15m');
    });
  });
}

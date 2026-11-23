import 'package:clock_app/core/utils/month_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthGrid.daysFor', () {
    test('November 2026 starts on Sunday-aligned grid (Sun Nov 1 → Sat Dec 5)', () {
      final days = MonthGrid.daysFor(DateTime(2026, 11));

      expect(days.first, DateTime(2026, 11, 1)); // Nov 1, 2026 is a Sunday
      expect(days.last, DateTime(2026, 12, 5));
      expect(days.length, 35);
    });

    test('pads leading days from the previous month', () {
      final days = MonthGrid.daysFor(DateTime(2026, 10)); // Oct 1 is Thursday

      expect(days.first, DateTime(2026, 9, 27)); // Sunday
      expect(days.first.weekday, DateTime.sunday);
    });

    test('always covers whole Sunday–Saturday weeks', () {
      for (var m = 1; m <= 12; m++) {
        final days = MonthGrid.daysFor(DateTime(2026, m));
        expect(days.length % 7, 0);
        expect(days.first.weekday, DateTime.sunday);
        expect(days.last.weekday, DateTime.saturday);
      }
    });

    test('can need six weeks', () {
      // May 2026 starts on Friday and has 31 days → 6 rows.
      expect(MonthGrid.daysFor(DateTime(2026, 5)).length, 42);
    });
  });

  test('shiftMonth wraps across years', () {
    expect(MonthGrid.shiftMonth(DateTime(2026, 11), 2), DateTime(2027, 1));
    expect(MonthGrid.shiftMonth(DateTime(2026, 1), -1), DateTime(2025, 12));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter.clockTime', () {
    test('formats as 12-hour with am/pm by default', () {
      expect(DateFormatter.clockTime(DateTime(2026, 1, 1, 8, 5)), '8:05 am');
      expect(DateFormatter.clockTime(DateTime(2026, 1, 1, 13, 30)), '1:30 pm');
    });

    test('formats as 24-hour with no am/pm when is12Hour is false', () {
      expect(DateFormatter.clockTime(DateTime(2026, 1, 1, 8, 5), is12Hour: false), '08:05');
      expect(DateFormatter.clockTime(DateTime(2026, 1, 1, 13, 30), is12Hour: false), '13:30');
    });

    test('24-hour format pads midnight as 00', () {
      expect(DateFormatter.clockTime(DateTime(2026, 1, 1, 0, 0), is12Hour: false), '00:00');
    });
  });
}

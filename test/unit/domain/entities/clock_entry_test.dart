import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/domain/entities/clock_entry.dart';

void main() {
  group('ClockEntry', () {
    test('isClockedIn should return true if clockedOutAt is null', () {
      final entry = ClockEntry(
        id: '1',
        clockedInAt: DateTime.now(),
      );

      expect(entry.isClockedIn, true);
    });

    test('isClockedIn should return false if clockedOutAt is not null', () {
      final entry = ClockEntry(
        id: '1',
        clockedInAt: DateTime.now().subtract(const Duration(hours: 1)),
        clockedOutAt: DateTime.now(),
      );

      expect(entry.isClockedIn, false);
    });

    test('elapsed should calculate duration correctly', () {
      final start = DateTime(2023, 1, 1, 9, 0, 0);
      final end = DateTime(2023, 1, 1, 17, 30, 0);
      
      final entry = ClockEntry(
        id: '1',
        clockedInAt: start,
        clockedOutAt: end,
      );

      expect(entry.elapsed, const Duration(hours: 8, minutes: 30));
    });
  });
}

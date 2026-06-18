import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/domain/entities/active_session.dart';

void main() {
  group('ActiveSession', () {
    final now = DateTime.now();

    test('should calculate elapsed duration correctly', () {
      final startTime = now.subtract(const Duration(hours: 1));
      final session = ActiveSession(
        clockedInAt: startTime,
      );

      // Elapsed should be roughly 1 hour
      expect(session.elapsed.inHours, 1);
    });

    test('copyWith should return a new instance with updated values', () {
      final session = ActiveSession(
        clockedInAt: now,
        alarmEnabled: false,
      );

      final updated = session.copyWith(alarmEnabled: true);

      expect(updated.alarmEnabled, true);
      expect(updated.clockedInAt, session.clockedInAt);
    });
  });
}

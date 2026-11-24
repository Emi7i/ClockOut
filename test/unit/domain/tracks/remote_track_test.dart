import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/domain/tracks/remote_track.dart';

void main() {
  // Sunday 22 Nov 2026 starts the week; Saturday 28 Nov ends it.
  final sunday = DateTime(2026, 11, 22);

  test('the week runs Sunday to Saturday', () {
    expect(startOfWeekSunday(DateTime(2026, 11, 22, 18)), sunday);
    expect(startOfWeekSunday(DateTime(2026, 11, 24)), sunday); // Tuesday
    expect(startOfWeekSunday(DateTime(2026, 11, 28, 23, 59)), sunday);
    expect(startOfWeekSunday(DateTime(2026, 11, 29)), DateTime(2026, 11, 29));
  });

  test('no remote day logged: available, the comet at the start', () {
    final s = remoteStatus(remoteDays: [], now: DateTime(2026, 11, 24));
    expect(s.available, isTrue);
    expect(s.progress, 0);
  });

  test('a remote day logged this week: used, the comet at the end', () {
    final s = remoteStatus(
      remoteDays: [DateTime(2026, 11, 23)],
      now: DateTime(2026, 11, 24),
    );
    expect(s.available, isFalse);
    expect(s.progress, 1);
  });

  test('a remote day later in the same week counts too', () {
    final s = remoteStatus(
      remoteDays: [DateTime(2026, 11, 27)],
      now: DateTime(2026, 11, 24),
    );
    expect(s.available, isFalse);
  });

  test('resets weekly: last week\'s remote day does not count', () {
    final days = [DateTime(2026, 11, 20)]; // Friday of the previous week
    expect(remoteStatus(remoteDays: days, now: DateTime(2026, 11, 21)).available,
        isFalse); // still that week (Saturday)
    expect(remoteStatus(remoteDays: days, now: DateTime(2026, 11, 22)).available,
        isTrue); // Sunday: new week, available again
  });

  test('the reset happens at the start of Sunday, not Monday', () {
    final days = [DateTime(2026, 11, 18)]; // Wednesday
    expect(
        remoteStatus(remoteDays: days, now: DateTime(2026, 11, 22, 0, 0, 1))
            .available,
        isTrue);
    expect(
        remoteStatus(remoteDays: days, now: DateTime(2026, 11, 21, 23, 59))
            .available,
        isFalse);
  });

  test('the time of day on a logged day does not matter', () {
    final s = remoteStatus(
      remoteDays: [DateTime(2026, 11, 22, 23, 59)],
      now: DateTime(2026, 11, 22, 0, 1),
    );
    expect(s.available, isFalse);
  });

  test('crosses a month boundary correctly', () {
    // 1 Nov 2026 is a Sunday; 31 Oct is a Saturday in the previous week.
    expect(startOfWeekSunday(DateTime(2026, 11, 1)), DateTime(2026, 11, 1));
    expect(startOfWeekSunday(DateTime(2026, 11, 3)), DateTime(2026, 11, 1));
    final s = remoteStatus(
      remoteDays: [DateTime(2026, 10, 31)],
      now: DateTime(2026, 11, 2),
    );
    expect(s.available, isTrue);
  });
}

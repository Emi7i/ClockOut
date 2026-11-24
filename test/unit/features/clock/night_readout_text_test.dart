import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/domain/tracks/bonus_track.dart';
import 'package:clock_app/domain/tracks/remote_track.dart';
import 'package:clock_app/domain/tracks/vacation_track.dart';
import 'package:clock_app/features/clock/widgets/scene/night_readout_text.dart';
import 'package:clock_app/features/clock/widgets/scene/night_track_values.dart';

void main() {
  test('labels are one or two words', () {
    expect(nightBodyLabel(NightBody.vacation), 'Vacation');
    expect(nightBodyLabel(NightBody.remote), 'Remote');
    expect(nightBodyLabel(NightBody.bonus), 'Bonus');
  });

  group('vacation', () {
    test('14 of 22 left', () {
      expect(vacationReadout(vacationStatus(usedDays: 8, convertedDays: 0)),
          '14 of 22 left');
    });
    test('converted days count towards the days available', () {
      expect(vacationReadout(vacationStatus(usedDays: 8, convertedDays: 3)),
          '17 of 25 left');
    });
    test('nothing left', () {
      expect(vacationReadout(vacationStatus(usedDays: 22, convertedDays: 0)),
          '0 of 22 left');
    });
  });

  group('remote', () {
    test('available', () {
      expect(remoteReadout(const RemoteStatus(available: true)),
          '1 left this week');
    });
    test('used', () {
      expect(remoteReadout(const RemoteStatus(available: false)),
          '0 left this week');
    });
  });

  group('bonus', () {
    String of(Duration d) => bonusReadout(bonusStatus(d));

    test('11h = 1 day ready + 3h', () {
      expect(of(const Duration(hours: 11)), '11h = 1 day ready + 3h');
    });
    test('exactly 8h: 1 day ready + 0h', () {
      expect(of(const Duration(hours: 8)), '8h = 1 day ready + 0h');
    });
    test('several days', () {
      expect(of(const Duration(hours: 19)), '19h = 2 days ready + 3h');
      expect(of(const Duration(hours: 16)), '16h = 2 days ready + 0h');
    });
    test('minutes are shown', () {
      expect(of(const Duration(hours: 8, minutes: 10)),
          '8h 10m = 1 day ready + 10m');
    });
    test('below a day says how far the next one is', () {
      expect(of(const Duration(hours: 2, minutes: 30)),
          '2h 30m · 5h 30m to the next day');
      expect(of(Duration.zero), '0h · 8h to the next day');
    });
    test('an overdrawn bank says so', () {
      expect(of(const Duration(hours: -3)), '−3h · below zero');
    });
  });

  test('formatHours', () {
    expect(formatHours(Duration.zero), '0h');
    expect(formatHours(const Duration(hours: 3)), '3h');
    expect(formatHours(const Duration(minutes: 45)), '45m');
    expect(formatHours(const Duration(hours: 1, minutes: 5)), '1h 5m');
    expect(formatHours(const Duration(minutes: -90)), '−1h 30m');
  });

  test('nightReadout picks the right text for each body', () {
    final values = NightTrackValues(
      vacation: vacationStatus(usedDays: 8, convertedDays: 0),
      remote: const RemoteStatus(available: true),
      bonus: bonusStatus(const Duration(hours: 11)),
    );
    expect(nightReadout(NightBody.vacation, values), '14 of 22 left');
    expect(nightReadout(NightBody.remote, values), '1 left this week');
    expect(nightReadout(NightBody.bonus, values), '11h = 1 day ready + 3h');
    expect(values.progressOf(NightBody.remote), 0);
  });

  test('the convert summary shows the bank and the days before and after', () {
    final values = NightTrackValues(
      vacation: vacationStatus(usedDays: 8, convertedDays: 1),
      remote: const RemoteStatus(available: true),
      bonus: bonusStatus(const Duration(hours: 8, minutes: 10)),
    );
    expect(
      convertSummary(values),
      'Bonus bank: 8h 10m → 10m\nVacation days available: 23 → 24',
    );
  });
}

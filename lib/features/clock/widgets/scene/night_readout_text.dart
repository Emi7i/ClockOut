import '../../../../core/constants/app_constants.dart';
import '../../../../domain/tracks/bonus_track.dart';
import '../../../../domain/tracks/remote_track.dart';
import '../../../../domain/tracks/vacation_track.dart';
import 'night_track_values.dart';

/// The words shown for the Night bodies. Pure functions, no widgets.

/// The short label under each body (one or two words).
String nightBodyLabel(NightBody body) => switch (body) {
      NightBody.vacation => 'Vacation',
      NightBody.remote => 'Remote',
      NightBody.bonus => 'Bonus',
    };

/// "14 of 22 left": days not yet taken, out of the days available (the yearly
/// allowance plus every day converted from bonus hours).
String vacationReadout(VacationStatus s) =>
    '${s.daysLeft} of ${s.daysAvailable} left';

/// "1 left this week" while the weekly remote day is free, "0 left this week"
/// once it has been used.
String remoteReadout(RemoteStatus s) =>
    '${s.available ? 1 : 0} left this week';

/// "11h = 1 day ready + 3h": the bank and how it splits into vacation days
/// that can be converted now plus what is left over. Below one day it says how
/// far off the next one is, and an overdrawn bank says so.
String bonusReadout(BonusStatus s) {
  if (s.balance < Duration.zero) {
    return '${formatHours(s.balance)} · below zero';
  }
  if (s.daysReady == 0) {
    final toGo = AppConstants.bonusPerVacationDay - s.balance;
    return '${formatHours(s.balance)} · ${formatHours(toGo)} to the next day';
  }
  final days = s.daysReady == 1 ? '1 day' : '${s.daysReady} days';
  return '${formatHours(s.balance)} = $days ready + ${formatHours(s.remainder)}';
}

/// "3h", "2h 30m", "45m", "0h"; a minus sign for a negative bank.
String formatHours(Duration d) {
  final negative = d < Duration.zero;
  final total = d.abs().inMinutes;
  final h = total ~/ 60;
  final m = total % 60;
  final text = switch ((h, m)) {
    (0, 0) => '0h',
    (_, 0) => '${h}h',
    (0, _) => '${m}m',
    _ => '${h}h ${m}m',
  };
  return negative ? '−$text' : text;
}

/// The readout text for [body] given the current [values].
String nightReadout(NightBody body, NightTrackValues values) =>
    switch (body) {
      NightBody.vacation => vacationReadout(values.vacation),
      NightBody.remote => remoteReadout(values.remote),
      NightBody.bonus => bonusReadout(values.bonus),
    };

/// What a conversion would do, for the confirmation dialog.
String convertSummary(NightTrackValues values) {
  final before = values.bonus.balance;
  final after = before - AppConstants.bonusPerVacationDay;
  final days = values.vacation.daysAvailable;
  return 'Bonus bank: ${formatHours(before)} → ${formatHours(after)}\n'
      'Vacation days available: $days → ${days + 1}';
}

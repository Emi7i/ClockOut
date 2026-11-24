import 'package:flutter/foundation.dart';

import '../../domain/tracks/bonus_track.dart';
import '../../domain/tracks/remote_track.dart';
import '../../domain/tracks/vacation_track.dart';
import 'widgets/scene/night_track_values.dart';

/// TEMPORARY: made-up stats for the Night bodies. There is no real data source
/// for them yet. Change a value here and the matching body moves along its
/// orbit (and the solid / dashed split with it). This is the ONLY place with
/// fake numbers; replace [fakeNightTrackValues] and [convertBonusDay] with
/// real data later.
///
/// The values live in memory only: converting changes them until the app is
/// restarted, then they are back to what is written here.
abstract final class FakeTrackStats {
  /// Vacation days already taken this year. The top comet travels as they are
  /// used up: 0 = start of its orbit, all days used = end.
  static int vacationUsedDays = 22;

  /// Vacation days converted from bonus hours so far.
  static int vacationConvertedDays = 1;

  /// Dates of the remote days logged. Empty = this week's remote day is still
  /// available (lower comet at the start). Add a date from this week (Sunday
  /// to Saturday) to see it used (comet at the end).
  static final List<DateTime> remoteDays = <DateTime>[];

  /// The time bank. The moon travels as hours are earned: 0 h = start, 8 h =
  /// end, and it wraps for every further 8 h.
  static Duration bonusBalance = const Duration(hours: 8, minutes: 10);

  /// Bumped whenever a value is changed by the app (a conversion), so the
  /// screen redraws. Edits made here in the source need a hot reload instead.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Converts 8 h of the bank into one vacation day. Returns false (and
  /// changes nothing) when the bank holds less than that.
  static bool convertBonusDayNow() {
    final c = convertBonusDay(
      balance: bonusBalance,
      convertedDays: vacationConvertedDays,
    );
    if (c == null) return false;
    bonusBalance = c.balance;
    vacationConvertedDays = c.convertedDays;
    changes.value++;
    return true;
  }
}

/// The Night bodies' stats for [now], computed from [FakeTrackStats].
NightTrackValues fakeNightTrackValues(DateTime now) => NightTrackValues(
      vacation: vacationStatus(
        usedDays: FakeTrackStats.vacationUsedDays,
        convertedDays: FakeTrackStats.vacationConvertedDays,
      ),
      remote: remoteStatus(remoteDays: FakeTrackStats.remoteDays, now: now),
      bonus: bonusStatus(FakeTrackStats.bonusBalance),
    );

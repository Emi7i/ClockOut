import '../../domain/tracks/bonus_track.dart';
import '../../domain/tracks/remote_track.dart';
import '../../domain/tracks/vacation_track.dart';
import 'widgets/scene/night_track_values.dart';

/// TEMPORARY: made-up stats for the Night bodies. There is no real data source
/// for them yet. Change a value here and the matching body moves along its
/// orbit (and the solid / dashed split with it). This is the ONLY place with
/// fake numbers; replace [fakeNightTrackValues] with real data later.
///
abstract final class FakeTrackStats {
  /// Vacation days already taken this year. The top comet travels as they are
  /// used up: 0 = start of its orbit, all days used = end.
  static const int vacationUsedDays = 22;

  /// Vacation days converted from bonus hours so far.
  static const int vacationConvertedDays = 1;

  /// Dates of the remote days logged. Empty = this week's remote day is still
  /// available (lower comet at the start). Add a date from this week (Sunday
  /// to Saturday) to see it used (comet at the end).
  static final List<DateTime> remoteDays = <DateTime>[];

  /// The time bank. The moon travels as hours are earned: 0 h = start, 8 h =
  /// end, and it wraps for every further 8 h.
  static const Duration bonusBalance = Duration(hours: 8, minutes: 10);
}

/// The Night bodies' positions for [now], computed from [FakeTrackStats].
NightTrackValues fakeNightTrackValues(DateTime now) => NightTrackValues(
      vacation: vacationStatus(
        usedDays: FakeTrackStats.vacationUsedDays,
        convertedDays: FakeTrackStats.vacationConvertedDays,
      ).progress,
      remote: remoteStatus(remoteDays: FakeTrackStats.remoteDays, now: now)
          .progress,
      bonus: bonusStatus(FakeTrackStats.bonusBalance).progress,
    );

/// How far along its orbit each Night body sits, 0 (start) … 1 (end).
///
/// The comets travel as allowances are USED UP (start = all still there,
/// end = all used); the moon travels as bonus hours are EARNED. These are the
/// outputs of the stat conversions in `lib/domain/tracks/`; the widgets only
/// ever see these three numbers.
class NightTrackValues {
  /// Top comet: the share of the year's vacation days already used.
  final double vacation;

  /// Lower comet: the weekly remote day (0 = still available, 1 = used).
  final double remote;

  /// Moon: bonus hours' progress to the next vacation day.
  final double bonus;

  const NightTrackValues({
    required this.vacation,
    required this.remote,
    required this.bonus,
  });
}

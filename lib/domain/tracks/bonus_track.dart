import '../../core/constants/app_constants.dart';

/// Where the user stands on the bonus-hours track: progress towards the next
/// vacation day that the balance can be converted into.
class BonusStatus {
  /// The whole time bank.
  final Duration balance;

  /// Vacation days that can be converted right now.
  final int daysReady;

  /// What is left over after those days (zero for an exact multiple, negative
  /// when the bank is overdrawn).
  final Duration remainder;

  /// 0 … 1 towards the next day.
  final double progress;

  const BonusStatus({
    required this.balance,
    required this.daysReady,
    required this.remainder,
    required this.progress,
  });
}

/// Bonus hours: [perDay] (8 h) buy one vacation day, convertible any time.
///
/// Progress is the way to the next day: `(balance mod 8 h) / 8 h`. It wraps
/// every 8 hours, but an exact multiple stays at the END of the track
/// ("1 day ready, 0 h over") and only wraps once the balance goes past it.
/// Nothing earned (zero, or an overdrawn bank) sits at the start.
BonusStatus bonusStatus(
  Duration balance, {
  Duration perDay = AppConstants.bonusPerVacationDay,
}) {
  if (balance <= Duration.zero) {
    return BonusStatus(
      balance: balance,
      daysReady: 0,
      remainder: balance,
      progress: 0,
    );
  }
  final days = balance.inMicroseconds ~/ perDay.inMicroseconds;
  final remainder = balance - perDay * days;
  final progress = remainder == Duration.zero
      ? 1.0
      : remainder.inMicroseconds / perDay.inMicroseconds;
  return BonusStatus(
    balance: balance,
    daysReady: days,
    remainder: remainder,
    progress: progress,
  );
}

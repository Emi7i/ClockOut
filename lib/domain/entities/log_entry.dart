/// ─────────────────────────────────────────────────────────────
///  LOG ENTRY  –  Domain Entity
///  A summarised record shown in the Logs screen.
/// ─────────────────────────────────────────────────────────────
enum LogStatus { onTime, early, late }

class LogEntry {
  final int? id;
  final DateTime date;
  final Duration bonusTime;
  final bool userEdited;
  final DateTime? clockedInTime;
  final DateTime? clockedOutTime;
  final bool onlineWork;

  const LogEntry({
    this.id,
    required this.date,
    required this.bonusTime,
    required this.userEdited,
    this.clockedInTime,
    this.clockedOutTime,
    required this.onlineWork,
  });

  /// Computes the bonus/deficit time for a shift, relative to when the
  /// shift was expected to end (clockedInAt + shiftDuration).
  ///
  /// Clocking out after the shift ended rounds DOWN to the nearest
  /// [bonusInterval] — e.g. 55 minutes past shift end still reads as a
  /// +30 bonus, while 60 minutes past reads as +60.
  ///
  /// Clocking out before the shift ended returns the exact deficit,
  /// unrounded (e.g. 5 minutes early is exactly -5).
  static Duration computeBonusTime({
    required DateTime clockedInAt,
    required DateTime clockedOutAt,
    required Duration shiftDuration,
    Duration bonusInterval = const Duration(minutes: 30),
  }) {
    final shiftEnd = clockedInAt.add(shiftDuration);
    final elapsed = clockedOutAt.difference(shiftEnd);

    if (elapsed.isNegative) return elapsed;

    final steps = elapsed.inMinutes ~/ bonusInterval.inMinutes;
    return bonusInterval * steps;
  }

  LogStatus get status {
    if (bonusTime.inMinutes == 0) return LogStatus.onTime;
    return bonusTime.isNegative ? LogStatus.late : LogStatus.early;
  }

  /// Human-readable offset string, e.g. "+30" / "+1h 30m" / "-5 minutes" /
  /// "-1h 15m" / "On Time"
  String get offsetLabel {
    switch (status) {
      case LogStatus.onTime:
        return 'On Time';
      case LogStatus.late:
        final mins = bonusTime.inMinutes.abs();
        return mins < 60 ? '-$mins minutes' : '-${_formatMinutes(mins)}';
      case LogStatus.early:
        return '+${_formatMinutes(bonusTime.inMinutes)}';
    }
  }

  /// Formats a non-negative minute count as plain minutes below an hour,
  /// or "Xh"/"Xh Ym" once it reaches 60.
  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
  }

  Duration get duration {
    if (clockedInTime == null || clockedOutTime == null) return Duration.zero;
    return clockedOutTime!.difference(clockedInTime!);
  }
}

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

  LogStatus get status {
    if (bonusTime.inMinutes == 0) return LogStatus.onTime;
    return bonusTime.isNegative ? LogStatus.late : LogStatus.early;
  }

  /// Human-readable offset string, e.g. "+ 30 mins" / "- 2 mins" / "On time"
  String get offsetLabel {
    if (status == LogStatus.onTime) return 'On time';
    final mins = bonusTime.inMinutes.abs();
    final sign  = bonusTime.isNegative ? '-' : '+';
    return '$sign $mins mins';
  }

  Duration get duration {
    if (clockedInTime == null || clockedOutTime == null) return Duration.zero;
    return clockedOutTime!.difference(clockedInTime!);
  }
}

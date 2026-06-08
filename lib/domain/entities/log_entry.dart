/// ─────────────────────────────────────────────────────────────
///  LOG ENTRY  –  Domain Entity
///  A summarised record shown in the Logs screen.
/// ─────────────────────────────────────────────────────────────
enum LogStatus { onTime, early, late }

class LogEntry {
  final DateTime date;
  final LogStatus status;

  /// Positive = early (e.g. +30 min), negative = late (e.g. -2 min).
  final Duration offset;

  const LogEntry({
    required this.date,
    required this.status,
    required this.offset,
  });

  /// Human-readable offset string, e.g. "+ 30 mins" / "- 2 mins" / "On time"
  String get offsetLabel {
    if (status == LogStatus.onTime) return 'On time';
    final mins = offset.inMinutes.abs();
    final sign  = offset.isNegative ? '-' : '+';
    return '$sign $mins mins';
  }
}

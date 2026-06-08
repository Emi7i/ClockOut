/// ─────────────────────────────────────────────────────────────
///  DATE FORMATTER
///  Central place for all date/time display logic.
///  Swap format strings here — UI updates automatically.
/// ─────────────────────────────────────────────────────────────
abstract final class DateFormatter {
  /// e.g. "8:55 am"
  static String clockTime(DateTime dt) {
    final hour   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute $period';
  }

  /// e.g. "24. 05."
  static String logDate(DateTime dt) {
    final day   = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day. $month.';
  }

  /// e.g. "2 h 55 min"
  static String duration(Duration d) {
    final h   = d.inHours;
    final min = d.inMinutes.remainder(60);
    if (h > 0) return '$h h $min min';
    return '$min min';
  }

  /// e.g. "15 min 30 s"
  static String countdown(Duration d) {
    final min = d.inMinutes.remainder(60);
    final sec = d.inSeconds.remainder(60);
    return '$min min $sec s';
  }
}

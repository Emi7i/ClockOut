/// ─────────────────────────────────────────────────────────────
///  DATE FORMATTER
///  Central place for all date/time display logic.
///  Swap format strings here — UI updates automatically.
/// ─────────────────────────────────────────────────────────────
abstract final class DateFormatter {
  /// e.g. "8:55 am" (12-hour) or "08:55" (24-hour).
  static String clockTime(DateTime dt, {bool is12Hour = true}) {
    final minute = dt.minute.toString().padLeft(2, '0');
    if (!is12Hour) {
      final hour = dt.hour.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final hour   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute $period';
  }

  /// e.g. "24. 05."
  static String logDate(DateTime dt) {
    final day   = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day. $month.';
  }

  /// e.g. "2 h 55 min" or "45 min 30 sec"
  static String duration(Duration d) {
    final h   = d.inHours;
    final min = d.inMinutes.remainder(60);
    final sec = d.inSeconds.remainder(60);
    if (h > 0) return '$h h $min min';
    return '$min min $sec sec';
  }

  /// e.g. "15min 30sec"
  static String countdown(Duration d) {
    final min = d.inMinutes.remainder(60);
    final sec = d.inSeconds.remainder(60);
    return '${min}min ${sec}sec';
  }
}

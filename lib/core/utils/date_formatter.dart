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

  static const List<String> _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdaysLong = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  /// Single-letter weekday labels, Sunday first.
  static const List<String> weekdayInitials = [
    'S', 'M', 'T', 'W', 'T', 'F', 'S',
  ];

  /// e.g. "7:00am" — compact 12-hour time without a space.
  static String compactTime(DateTime dt) =>
      clockTime(dt).replaceFirst(' ', '');

  /// e.g. "Nov 2026"
  static String monthYear(DateTime dt) =>
      '${_monthsShort[dt.month - 1]} ${dt.year}';

  /// e.g. "Monday, Nov 23"
  static String weekdayMonthDay(DateTime dt) =>
      '${_weekdaysLong[dt.weekday - 1]}, ${_monthsShort[dt.month - 1]} ${dt.day}';

  /// e.g. "24 / 05 / 2026" (day / month / year).
  static String slashDate(DateTime dt) {
    final day   = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day / $month / ${dt.year}';
  }

  /// e.g. "Mon   24 / 05 / 2026".
  static String weekdaySlashDate(DateTime dt) =>
      '${_weekdaysLong[dt.weekday - 1].substring(0, 3)}   ${slashDate(dt)}';

  /// e.g. "30 minutes", "1h" or "1h 30m".
  static String bonusDuration(Duration d) {
    final minutes = d.inMinutes.abs();
    if (minutes < 60) return '$minutes minutes';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
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

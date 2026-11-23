/// ─────────────────────────────────────────────────────────────
///  MONTH GRID
///  Pure date helpers for laying out a Sunday–Saturday calendar.
/// ─────────────────────────────────────────────────────────────
abstract final class MonthGrid {
  static const int daysPerWeek = 7;

  /// Strips the time component so dates can be used as map keys.
  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Every day shown for [month], padded with days of the neighbouring
  /// months so the list always covers whole Sunday–Saturday weeks.
  static List<DateTime> daysFor(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    // DateTime.weekday: Monday = 1 … Sunday = 7 → Sunday maps to 0.
    final leading = first.weekday % daysPerWeek;
    final trailing = (daysPerWeek - 1) - (last.weekday % daysPerWeek);
    final count = leading + last.day + trailing;

    return List.generate(
      count,
      (i) => DateTime(first.year, first.month, 1 - leading + i),
    );
  }

  /// The first day of the month [offset] months away from [month].
  static DateTime shiftMonth(DateTime month, int offset) =>
      DateTime(month.year, month.month + offset);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

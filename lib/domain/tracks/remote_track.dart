/// Where the user stands on the remote-day track: one remote day a week.
///
/// Only two positions exist: the day is still available (start of the track)
/// or it has been used (end). It resets when a new week begins.
class RemoteStatus {
  final bool available;
  const RemoteStatus({required this.available});

  /// 0 = the day is still available, 1 = used this week.
  double get progress => available ? 0 : 1;
}

/// The Sunday that starts the week containing [day] (time of day dropped).
/// The week runs Sunday to Saturday, like the calendar grid.
DateTime startOfWeekSunday(DateTime day) {
  // DateTime.weekday is Monday = 1 … Sunday = 7, so Sunday % 7 = 0.
  return DateTime(day.year, day.month, day.day - day.weekday % 7);
}

/// Remote day: available unless a remote day was logged in the week that
/// contains [now]. [remoteDays] are the dates of every logged remote day;
/// the time of day does not matter.
RemoteStatus remoteStatus({
  required Iterable<DateTime> remoteDays,
  required DateTime now,
}) {
  final weekStart = startOfWeekSunday(now);
  final nextWeekStart =
      DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
  final usedThisWeek = remoteDays.any((d) {
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(weekStart) && day.isBefore(nextWeekStart);
  });
  return RemoteStatus(available: !usedThisWeek);
}

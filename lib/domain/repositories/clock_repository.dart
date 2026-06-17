import '../entities/clock_entry.dart';
import '../entities/log_entry.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK REPOSITORY  –  Abstract Contract (Domain Layer)
///  The data layer must implement this interface.
///  Features depend only on this abstraction, never on the impl.
/// ─────────────────────────────────────────────────────────────
abstract interface class ClockRepository {
  /// Returns the active session, or null if not clocked in.
  Future<ClockEntry?> getActiveEntry();

  /// Starts a new clock-in session.
  Future<ClockEntry> clockIn();

  /// Ends the active session.
  Future<ClockEntry> clockOut();

  /// Returns all historical log entries, newest first.
  Future<List<LogEntry>> getLogs();

  /// Deletes every stored log permanently.
  Future<void> deleteAllLogs();

  /// Toggles the alarm for the active session.
  Future<void> setAlarm({required bool enabled});

  /// Updates the clock-in time for the currently active session.
  Future<void> updateActiveClockInTime(DateTime newTime);
}

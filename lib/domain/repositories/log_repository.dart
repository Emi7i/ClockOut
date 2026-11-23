import '../entities/log_entry.dart';

/// ─────────────────────────────────────────────────────────────
///  LOG REPOSITORY  –  Abstract Contract
/// ─────────────────────────────────────────────────────────────
abstract interface class LogRepository {
  static late LogRepository Function() build;

  /// Returns all historical log entries.
  Future<List<LogEntry>> getLogs();

  /// Stores a new log entry.
  Future<void> addLog(LogEntry entry);

  /// Deletes every stored log.
  Future<void> deleteAllLogs();

  /// Deletes a single stored log by id.
  Future<void> deleteLog(int id);

  /// Persists changes to an existing log entry (e.g. a user edit).
  Future<void> updateLog(LogEntry entry);
}

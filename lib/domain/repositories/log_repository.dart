import '../entities/log_entry.dart';

/// ─────────────────────────────────────────────────────────────
///  LOG REPOSITORY  –  Abstract Contract
/// ─────────────────────────────────────────────────────────────
abstract interface class LogRepository {
  static late LogRepository Function() build;

  /// Returns all historical log entries.
  Future<List<LogEntry>> getLogs();

  /// Deletes every stored log.
  Future<void> deleteAllLogs();

  /// Persists changes to an existing log entry (e.g. a user edit).
  Future<void> updateLog(LogEntry entry);
}

import '../entities/log_entry.dart';

/// ─────────────────────────────────────────────────────────────
///  LOG REPOSITORY  –  Abstract Contract
/// ─────────────────────────────────────────────────────────────
abstract interface class LogRepository {
  /// Returns all historical log entries.
  Future<List<LogEntry>> getLogs();

  /// Deletes every stored log.
  Future<void> deleteAllLogs();
}

import '../entities/log_entry.dart';
import '../repositories/log_repository.dart';

/// ─────────────────────────────────────────────────────────────
///  GET LOGS USE CASE
/// ─────────────────────────────────────────────────────────────
class GetLogsUseCase {
  final LogRepository _repository;

  const GetLogsUseCase(this._repository);

  Future<List<LogEntry>> call() => _repository.getLogs();
}

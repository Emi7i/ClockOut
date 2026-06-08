import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/database_manager.dart';
import '../mappers/log_mapper.dart';

class LogRepositoryImpl implements LogRepository {
  final DatabaseManager _dbManager;

  LogRepositoryImpl({DatabaseManager? dbManager}) 
      : _dbManager = dbManager ?? DatabaseManager();

  @override
  Future<List<LogEntry>> getLogs() async {
    final dtos = await _dbManager.getAllLogs();
    return dtos
        .where((d) => d.clockedOutTime != null) // Only completed sessions
        .map(LogMapper.fromDto)
        .toList();
  }

  @override
  Future<void> deleteAllLogs() async {
    final logs = await _dbManager.getAllLogs();
    for (final log in logs) {
      if (log.id != null) {
        await _dbManager.deleteLog(log.id!);
      }
    }
  }
}

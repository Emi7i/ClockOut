import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/database_manager.dart';
import '../mappers/log_mapper.dart';
import '../datasources/local/database_helper.dart';

class LogRepositoryImpl implements LogRepository {
  final DatabaseManager _dbManager;

  LogRepositoryImpl(this._dbManager);

  @override
  Future<List<LogEntry>> getLogs() async {
    final dtos = await _dbManager.getAllLogs();
    return dtos.map(LogMapper.toEntity).toList();
  }

  @override
  Future<void> deleteAllLogs() async {
    final db = await _dbManager.database;
    await db.delete(DatabaseHelper.tableLogs);
  }
}

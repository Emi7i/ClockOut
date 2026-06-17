import '../../domain/entities/clock_entry.dart';
import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/clock_repository.dart';
import '../datasources/database_manager.dart';
import '../dtos/log_dto.dart';
import '../mappers/clock_entry_mapper.dart';
import '../mappers/log_mapper.dart';

class ClockRepositoryImpl implements ClockRepository {
  final DatabaseManager _dbManager;

  ClockRepositoryImpl({DatabaseManager? dbManager}) 
      : _dbManager = dbManager ?? DatabaseManager();

  @override
  Future<ClockEntry?> getActiveEntry() async {
    final allLogs = await _dbManager.getAllLogs();
    // In our schema, active session has no clockedOutTime
    try {
      final activeDto = allLogs.firstWhere((log) => log.clockedOutTime == null);
      return ClockEntryMapper.fromDto(activeDto);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ClockEntry> clockIn() async {
    final now = DateTime.now();
    final dto = LogDto(
      dateAdded:     now.toIso8601String(),
      clockedInTime: now.toIso8601String(),
      bonusTime:     '0',
      userEdited:    0,
      onlineWork:    0,
    );
    
    final id = await _dbManager.insertLog(dto);
    return ClockEntryMapper.fromDto(LogDto(
      id:            id,
      dateAdded:     dto.dateAdded,
      clockedInTime: dto.clockedInTime,
      bonusTime:     dto.bonusTime,
      userEdited:    dto.userEdited,
      onlineWork:    dto.onlineWork,
    ));
  }

  @override
  Future<ClockEntry> clockOut() async {
    final active = await getActiveEntry();
    if (active == null) throw Exception('No active session to clock out of');

    final updated = active.copyWith(clockedOutAt: DateTime.now());
    await _dbManager.updateLog(ClockEntryMapper.toDto(updated));
    
    return updated;
  }

  @override
  Future<List<LogEntry>> getLogs() async {
    final dtos = await _dbManager.getAllLogs();
    // Return only those that ARE clocked out (history)
    return dtos
        .where((d) => d.clockedOutTime != null)
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

  @override
  Future<void> setAlarm({required bool enabled}) async {
    // This implementation depends on where you want to store the "enabled" flag.
    // In ClockBloc it was just a local state, but for persistence it should be in settings.
  }

  @override
  Future<void> updateActiveClockInTime(DateTime newTime) async {
    final active = await getActiveEntry();
    if (active == null) throw Exception('No active session to update');

    final updated = active.copyWith(
      clockedInAt: newTime,
    );
    await _dbManager.updateLog(ClockEntryMapper.toDto(updated));
  }
}

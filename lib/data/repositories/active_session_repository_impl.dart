import '../../core/constants/constants.dart';
import '../../domain/entities/active_session.dart';
import '../../domain/entities/log_entry.dart';
import '../../domain/repositories/active_session_repository.dart';
import '../datasources/database_manager.dart';
import '../mappers/active_session_mapper.dart';
import '../mappers/log_mapper.dart';
import '../datasources/local/database_helper.dart';

class ActiveSessionRepositoryImpl implements ActiveSessionRepository {
  final DatabaseManager _dbManager;

  ActiveSessionRepositoryImpl(this._dbManager);

  @override
  Future<ActiveSession?> getActiveSession() async {
    final dto = await _dbManager.getActiveSession();
    return dto != null ? ActiveSessionMapper.toEntity(dto) : null;
  }

  @override
  Future<ActiveSession> clockIn({bool alarmEnabled = false}) async {
    final session = ActiveSession(
      clockedInAt: DateTime.now(),
      alarmEnabled: alarmEnabled,
    );
    await _dbManager.setActiveSession(ActiveSessionMapper.toDto(session));
    return session;
  }

  @override
  Future<ActiveSession> clockOut() async {
    final activeSession = await getActiveSession();
    if (activeSession == null) {
      throw Exception('No active session to clock out from.');
    }

    final now = DateTime.now();
    final bonusTime = LogEntry.computeBonusTime(
      clockedInAt: activeSession.clockedInAt,
      clockedOutAt: now,
      shiftDuration: AppConstants.shiftDuration,
    );
    final logEntry = LogEntry(
      date: activeSession.clockedInAt,
      bonusTime: bonusTime,
      userEdited: false,
      clockedInTime: activeSession.clockedInAt,
      clockedOutTime: now,
      onlineWork: false,
    );

    final db = await _dbManager.database;
    await db.transaction((txn) async {
      await txn.insert(DatabaseHelper.tableLogs, LogMapper.toDto(logEntry).toMap());
      await txn.delete(DatabaseHelper.tableActiveSession);
    });

    return activeSession;
  }

  @override
  Future<void> updateActiveSession(ActiveSession session) async {
    await _dbManager.setActiveSession(ActiveSessionMapper.toDto(session));
  }

  @override
  Future<void> setAlarmSound({required bool enabled}) async {

    final activeSession = await getActiveSession();
    if (activeSession != null) {
      final updated = activeSession.copyWith(alarmEnabled: enabled);
      await _dbManager.setActiveSession(ActiveSessionMapper.toDto(updated));
    }
  }

  @override
  Future<void> updateActiveClockInTime(DateTime newTime) async {
    final activeSession = await getActiveSession();
    if (activeSession != null) {
      final updated = activeSession.copyWith(clockedInAt: newTime);
      await _dbManager.setActiveSession(ActiveSessionMapper.toDto(updated));
    }
  }
}

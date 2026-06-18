import 'package:sqflite/sqflite.dart';
import 'local/database_helper.dart';
import '../dtos/log_dto.dart';
import '../dtos/user_settings_dto.dart';
import '../dtos/active_session_dto.dart';

/// ─────────────────────────────────────────────────────────────
///  DATABASE MANAGER
///  High-level API for performing CRUD operations using DTOs.
///  Connects to [DatabaseHelper] to access the SQLite instance.
/// ─────────────────────────────────────────────────────────────
class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  factory DatabaseManager() => _instance;

  DatabaseManager._internal();

  /// Proxy to get the database from DatabaseHelper
  Future<Database> get database => _dbHelper.database;

  // --- Logs Helper Methods ---

  Future<int> insertLog(LogDto log) async {
    final db = await database;
    return await db.insert(DatabaseHelper.tableLogs, log.toMap());
  }

  Future<List<LogDto>> getAllLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableLogs,
      orderBy: '${DatabaseHelper.colDateAdded} DESC',
    );
    return List.generate(maps.length, (i) => LogDto.fromMap(maps[i]));
  }

  Future<int> updateLog(LogDto log) async {
    final db = await database;
    return await db.update(
      DatabaseHelper.tableLogs,
      log.toMap(),
      where: '${DatabaseHelper.colLogId} = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteLog(int id) async {
    final db = await database;
    return await db.delete(
      DatabaseHelper.tableLogs,
      where: '${DatabaseHelper.colLogId} = ?',
      whereArgs: [id],
    );
  }

  // --- Settings Helper Methods ---

  Future<UserSettingsDto?> getSettings() async {
    final db = await database;
    final results = await db.query(DatabaseHelper.tableSettings, limit: 1);
    return results.isNotEmpty ? UserSettingsDto.fromMap(results.first) : null;
  }

  Future<int> updateSettings(UserSettingsDto settings) async {
    final db = await database;
    return await db.update(
      DatabaseHelper.tableSettings,
      settings.toMap(),
      where: '${DatabaseHelper.colSettingsId} = ?',
      whereArgs: [settings.id ?? 1],
    );
  }

  // --- Active Session Helper Methods ---

  Future<ActiveSessionDto?> getActiveSession() async {
    final db = await database;
    final results = await db.query(DatabaseHelper.tableActiveSession, limit: 1);
    return results.isNotEmpty ? ActiveSessionDto.fromMap(results.first) : null;
  }

  Future<void> setActiveSession(ActiveSessionDto session) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DatabaseHelper.tableActiveSession);
      await txn.insert(DatabaseHelper.tableActiveSession, session.toMap());
    });
  }

  Future<void> clearActiveSession() async {
    final db = await database;
    await db.delete(DatabaseHelper.tableActiveSession);
  }

  /// Closes the database via the helper.
  Future<void> close() async {
    await _dbHelper.close();
  }
}

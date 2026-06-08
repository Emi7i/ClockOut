import 'package:sqflite/sqflite.dart';
import 'local/database_helper.dart';

/// ─────────────────────────────────────────────────────────────
///  DATABASE MANAGER
///  High-level API for performing CRUD operations.
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

  Future<int> insertLog(Map<String, dynamic> log) async {
    final db = await database;
    return await db.insert(DatabaseHelper.tableLogs, log);
  }

  Future<List<Map<String, dynamic>>> getAllLogs() async {
    final db = await database;
    return await db.query(
      DatabaseHelper.tableLogs,
      orderBy: '${DatabaseHelper.colDateAdded} DESC',
    );
  }

  Future<int> updateLog(int id, Map<String, dynamic> log) async {
    final db = await database;
    return await db.update(
      DatabaseHelper.tableLogs,
      log,
      where: '${DatabaseHelper.colLogId} = ?',
      whereArgs: [id],
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

  Future<Map<String, dynamic>?> getSettings() async {
    final db = await database;
    final results = await db.query(DatabaseHelper.tableSettings, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateSettings(Map<String, dynamic> settings) async {
    final db = await database;
    return await db.update(
      DatabaseHelper.tableSettings,
      settings,
      where: '${DatabaseHelper.colSettingsId} = ?',
      whereArgs: [1], // Assuming only one row of settings exists
    );
  }

  /// Closes the database via the helper.
  Future<void> close() async {
    await _dbHelper.close();
  }
}

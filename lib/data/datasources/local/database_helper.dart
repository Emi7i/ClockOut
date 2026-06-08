import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// ─────────────────────────────────────────────────────────────
///  DATABASE HELPER
///  Manages the SQLite database lifecycle (creation, versioning).
///  Uses the Singleton pattern to ensure one DB connection.
/// ─────────────────────────────────────────────────────────────
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static String _dbName = 'clockout_database.db';

  // Table Names
  static const String tableLogs = 'Logs';
  static const String tableSettings = 'UserSettings';

  // Column Names - Logs
  static const String colLogId = 'log_id';
  static const String colDateAdded = 'date_added';
  static const String colBonusTime = 'bonus_time';
  static const String colUserEdited = 'user_edited';
  static const String colClockedInTime = 'clocked_in_time';
  static const String colClockedOutTime = 'clocked_out_time';
  static const String colOnlineWork = 'online_work';

  // Column Names - Settings
  static const String colSettingsId = 'settings_id';
  static const String colAccentColor = 'accent_color';
  static const String colClockFormat = 'clock_format';
  static const String colTimeDelay = 'time_delay';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// FOR TESTING ONLY: Set a custom DB name (e.g. inMemoryDatabasePath)
  static void setTestDbName(String name) => _dbName = name;

  /// FOR TESTING ONLY: Resets the singleton and closes the database.
  static void reset() {
    _database?.close();
    _database = null;
    _dbName = 'clockout_database.db';
  }

  /// Lazy getter for the database instance.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the connection to the local database file.
  Future<Database> _initDatabase() async {
    String path;
    if (_dbName == inMemoryDatabasePath) {
      path = inMemoryDatabasePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, _dbName);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Runs only when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Create Logs Table
    await db.execute('''
      CREATE TABLE $tableLogs (
        $colLogId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        $colDateAdded TEXT NOT NULL,
        $colBonusTime TEXT DEFAULT ('0') NOT NULL,
        $colUserEdited NUMERIC DEFAULT (0) NOT NULL,
        $colClockedInTime TEXT,
        $colClockedOutTime INTEGER,
        $colOnlineWork INTEGER DEFAULT (0)
      )
    ''');

    // 2. Create UserSettings Table
    await db.execute('''
      CREATE TABLE $tableSettings (
        $colSettingsId INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        $colAccentColor TEXT,
        $colClockFormat TEXT,
        $colTimeDelay INTEGER DEFAULT (30) NOT NULL
      )
    ''');

    // 3. Seed initial settings
    await db.insert(tableSettings, {
      colAccentColor: '0xFF4CAF50', // Default green
      colClockFormat: '24h',
      colTimeDelay: 30,
    });
  }

  /// Handles database schema updates (Migrations).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    /* 
    EXAMPLE MIGRATION (Version 1 -> 2):
    if (oldVersion < 2) {
       await db.execute('ALTER TABLE $tableLogs ADD COLUMN notes TEXT');
    }
    */
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

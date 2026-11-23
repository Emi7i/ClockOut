import 'package:clock_app/data/datasources/database_manager.dart';
import 'package:clock_app/data/datasources/local/database_helper.dart';
import 'package:clock_app/data/repositories/log_repository_impl.dart';
import 'package:clock_app/domain/entities/log_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Logs vacation column', () {
    const dbName = 'vacation_migration_test.db';
    late String dbPath;

    setUp(() async {
      DatabaseHelper.reset();
      dbPath = join(await getDatabasesPath(), dbName);
      await deleteDatabase(dbPath);
    });

    tearDown(() async {
      await DatabaseManager().close();
      DatabaseHelper.reset();
      await deleteDatabase(dbPath);
    });

    test('upgrading a v2 database adds the column; old rows read as not vacation',
        () async {
      // A database exactly as shipped at schema version 2 (no vacation column).
      final v2 = await openDatabase(
        dbPath,
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE Logs (
              log_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              date_added TEXT NOT NULL,
              bonus_time INTEGER DEFAULT (0) NOT NULL,
              user_edited NUMERIC DEFAULT (0) NOT NULL,
              clocked_in_time TEXT,
              clocked_out_time TEXT,
              online_work INTEGER DEFAULT (0)
            )
          ''');
          await db.execute('''
            CREATE TABLE UserSettings (
              settings_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              accent_color TEXT, clock_format TEXT,
              time_delay INTEGER DEFAULT (30) NOT NULL, recent_colors TEXT
            )
          ''');
          await db.insert('Logs', {
            'date_added': '2026-11-20T07:00:00.000',
            'bonus_time': 30,
            'user_edited': 0,
            'online_work': 1,
          });
        },
      );
      await v2.close();

      // Opening it through the app's helper runs the v2 → v3 migration.
      DatabaseHelper.setTestDbName(dbName);
      final repo = LogRepositoryImpl(DatabaseManager());
      final logs = await repo.getLogs();

      expect(logs, hasLength(1));
      expect(logs.single.onlineWork, isTrue); // untouched
      expect(logs.single.vacation, isFalse); // defaulted by the migration
      expect(logs.single.bonusTime, const Duration(minutes: 30));
    });

    test('a vacation log can be added and read back', () async {
      DatabaseHelper.setTestDbName(dbName);
      final repo = LogRepositoryImpl(DatabaseManager());

      await repo.addLog(LogEntry.manual(
        type: LogType.vacation,
        day: DateTime(2026, 11, 25, 13, 30),
        shiftDuration: const Duration(hours: 8),
      ));

      final logs = await repo.getLogs();
      expect(logs, hasLength(1));
      expect(logs.single.type, LogType.vacation);
      expect(logs.single.date, DateTime(2026, 11, 25));
      expect(logs.single.clockedInTime, isNull);
    });
  });
}

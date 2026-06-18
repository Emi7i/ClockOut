import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clock_app/data/repositories/active_session_repository_impl.dart';
import 'package:clock_app/data/datasources/database_manager.dart';
import 'package:clock_app/data/datasources/local/database_helper.dart';

void main() {
  // Initialize ffi for sqflite in tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ActiveSessionRepositoryImpl Integration', () {
    late ActiveSessionRepositoryImpl repository;
    late DatabaseManager dbManager;

    setUp(() async {
      // Configure DatabaseHelper to use in-memory DB for this test
      DatabaseHelper.reset();
      DatabaseHelper.setTestDbName(inMemoryDatabasePath);
      
      dbManager = DatabaseManager();
      repository = ActiveSessionRepositoryImpl(dbManager);
    });

    tearDown(() async {
      await dbManager.close();
      DatabaseHelper.reset();
    });

    test('clockIn should set an active session', () async {
      final session = await repository.clockIn();
      
      expect(session.clockedInAt, isNotNull);
      
      final active = await repository.getActiveSession();
      expect(active?.clockedInAt.toIso8601String(), session.clockedInAt.toIso8601String());
    });

    test('clockOut should clear the active session and create a log', () async {
      await repository.clockIn();
      await repository.clockOut();
      
      final active = await repository.getActiveSession();
      expect(active, isNull);

      final db = await dbManager.database;
      final logs = await db.query(DatabaseHelper.tableLogs);
      expect(logs.length, 1);
    });

    test('setAlarm should update the active session', () async {
      await repository.clockIn();
      await repository.setAlarm(enabled: true);
      
      final active = await repository.getActiveSession();
      expect(active?.alarmEnabled, true);
    });
  });
}

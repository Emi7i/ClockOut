import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clock_app/data/repositories/clock_repository_impl.dart';
import 'package:clock_app/data/datasources/database_manager.dart';
import 'package:clock_app/data/datasources/local/database_helper.dart';

void main() {
  // Initialize ffi for sqflite in tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ClockRepositoryImpl Integration', () {
    late ClockRepositoryImpl repository;

    setUp(() async {
      // Configure DatabaseHelper to use in-memory DB for this test
      DatabaseHelper.reset();
      DatabaseHelper.setTestDbName(inMemoryDatabasePath);
      
      repository = ClockRepositoryImpl();
    });

    tearDown(() async {
      await DatabaseHelper().close();
      DatabaseHelper.reset();
    });

    test('clockIn should insert a log and return a ClockEntry', () async {
      final entry = await repository.clockIn();
      
      expect(entry.isClockedIn, true);
      expect(entry.id, isNotEmpty);
      
      final active = await repository.getActiveEntry();
      expect(active?.id, entry.id);
    });

    test('clockOut should update the active log', () async {
      await repository.clockIn();
      final entry = await repository.clockOut();
      
      expect(entry.isClockedIn, false);
      expect(entry.clockedOutAt, isNotNull);
      
      final active = await repository.getActiveEntry();
      expect(active, isNull);
    });
  });
}

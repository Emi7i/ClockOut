import 'dart:io';
import 'package:clock_app/domain/entities/log_entry.dart';
import 'package:clock_app/features/calendar/cat_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LogEntry log({int bonus = 0, bool online = false}) => LogEntry(
        date: DateTime(2026, 11, 23),
        bonusTime: Duration(minutes: bonus),
        userEdited: false,
        onlineWork: online,
      );

  test('bonus time → bonus cat', () {
    expect(CatAssets.forLog(log(bonus: 30)), CatAssets.bonusTime);
    expect(CatAssets.forLog(log(bonus: 90)), CatAssets.bonusTime);
  });

  test('leaving early → early leave cat', () {
    expect(CatAssets.forLog(log(bonus: -5)), CatAssets.earlyLeave);
  });

  test('a normal shift → worker cat', () {
    expect(CatAssets.forLog(log()), CatAssets.worker);
  });

  test('15 minutes over adds no bonus, so it is still a worker day', () {
    final clockedIn = DateTime(2026, 11, 23, 7);
    final entry = LogEntry(
      date: clockedIn,
      bonusTime: LogEntry.computeBonusTime(
        clockedInAt: clockedIn,
        clockedOutAt: DateTime(2026, 11, 23, 15, 15),
        shiftDuration: const Duration(hours: 8),
      ),
      userEdited: false,
      onlineWork: false,
    );
    expect(CatAssets.forLog(entry), CatAssets.worker);
  });

  test('remote work always gets the remote cat', () {
    expect(CatAssets.forLog(log(online: true)), CatAssets.remoteWork);
    expect(CatAssets.forLog(log(bonus: 30, online: true)), CatAssets.remoteWork);
  });

  test('every referenced cat file exists', () {
    for (final path in [
      CatAssets.remoteWork,
      CatAssets.bonusTime,
      CatAssets.earlyLeave,
      CatAssets.worker,
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}

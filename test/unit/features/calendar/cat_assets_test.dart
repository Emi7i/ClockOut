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

  test('vacation gets the vacation cat', () {
    final vacation = LogEntry.manual(
      type: LogType.vacation,
      day: DateTime(2026, 11, 23),
      shiftDuration: const Duration(hours: 8),
    );
    expect(CatAssets.forLog(vacation), CatAssets.vacation);
  });

  test('manual logs: remote/vacation have no times or bonus; normal computes it', () {
    final remote = LogEntry.manual(
      type: LogType.remote,
      day: DateTime(2026, 11, 23, 14),
      shiftDuration: const Duration(hours: 8),
    );
    expect(remote.onlineWork, isTrue);
    expect(remote.clockedInTime, isNull);
    expect(remote.bonusTime, Duration.zero);
    expect(remote.date, DateTime(2026, 11, 23));

    final normal = LogEntry.manual(
      type: LogType.normal,
      day: DateTime(2026, 11, 23),
      clockedIn: DateTime(2026, 11, 23, 7),
      clockedOut: DateTime(2026, 11, 23, 15, 45),
      shiftDuration: const Duration(hours: 8),
    );
    expect(normal.bonusTime, const Duration(minutes: 30));
    expect(normal.type, LogType.normal);
  });

  test('every referenced cat file exists (light and dark)', () {
    for (final path in [
      CatAssets.vacation,
      CatAssets.vacation.replaceFirst('_dark', ''),
      CatAssets.remoteWork,
      CatAssets.bonusTime,
      CatAssets.earlyLeave,
      CatAssets.worker,
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}

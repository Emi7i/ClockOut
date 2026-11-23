import 'package:clock_app/domain/entities/log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const shift = Duration(hours: 8);

  LogEntry worked(int bonusMinutes) => LogEntry(
        date: DateTime(2026, 11, 2),
        bonusTime: Duration(minutes: bonusMinutes),
        userEdited: false,
        onlineWork: false,
      );

  LogEntry vacation({required bool useBank, int day = 3}) => LogEntry.manual(
        type: LogType.vacation,
        day: DateTime(2026, 11, day),
        shiftDuration: shift,
        useBank: useBank,
      );

  group('vacation paid from the time bank', () {
    test('costs one full shift', () {
      final log = vacation(useBank: true);
      expect(log.type, LogType.vacation);
      expect(log.usedBank, isTrue);
      expect(log.bonusTime, -shift);
    });

    test('a plain vacation costs nothing', () {
      final log = vacation(useBank: false);
      expect(log.usedBank, isFalse);
      expect(log.bonusTime, Duration.zero);
    });

    test('the flag is ignored for remote and normal logs', () {
      final remote = LogEntry.manual(
        type: LogType.remote,
        day: DateTime(2026, 11, 3),
        shiftDuration: shift,
        useBank: true,
      );
      expect(remote.usedBank, isFalse);
      expect(remote.bonusTime, Duration.zero);
    });

    test('a normal log that left early is not a bank vacation', () {
      expect(worked(-30).usedBank, isFalse);
    });
  });

  group('LogEntry.bankBalance', () {
    test('is empty at first', () {
      expect(LogEntry.bankBalance([]), Duration.zero);
    });

    test('bonus adds and leaving early takes away', () {
      expect(
        LogEntry.bankBalance([worked(60), worked(30), worked(-45)]),
        const Duration(minutes: 45),
      );
    });

    test('bank vacation takes a full day from collected time', () {
      final balance = LogEntry.bankBalance([
        worked(300), // 5h collected
        vacation(useBank: true), // -8h
      ]);
      expect(balance, const Duration(hours: -3));
    });

    test('can go negative and still be taken from', () {
      final balance = LogEntry.bankBalance([
        vacation(useBank: true, day: 3),
        vacation(useBank: true, day: 4),
      ]);
      expect(balance, const Duration(hours: -16));
    });

    test('collecting time again brings a negative balance back up', () {
      final balance = LogEntry.bankBalance([
        vacation(useBank: true),
        worked(120),
        worked(30),
      ]);
      expect(balance, const Duration(hours: -5, minutes: -30));
    });

    test('plain vacation and remote days leave it untouched', () {
      final balance = LogEntry.bankBalance([
        worked(90),
        vacation(useBank: false),
      ]);
      expect(balance, const Duration(minutes: 90));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/data/dtos/log_dto.dart';
import 'package:clock_app/data/mappers/log_mapper.dart';
import 'package:clock_app/domain/entities/log_entry.dart';

void main() {
  group('LogMapper', () {
    test('toEntity should map correctly', () {
      final dto = LogDto(
        id: 1,
        dateAdded: '2023-01-01T12:00:00Z',
        bonusTime: 30,
        userEdited: 1,
        clockedInTime: '2023-01-01T04:00:00Z',
        clockedOutTime: '2023-01-01T12:30:00Z',
        onlineWork: 1,
      );

      final entity = LogMapper.toEntity(dto);

      expect(entity.id, 1);
      expect(entity.date, DateTime.parse('2023-01-01T12:00:00Z'));
      expect(entity.bonusTime, const Duration(minutes: 30));
      expect(entity.userEdited, true);
      expect(entity.clockedInTime, DateTime.parse('2023-01-01T04:00:00Z'));
      expect(entity.clockedOutTime, DateTime.parse('2023-01-01T12:30:00Z'));
      expect(entity.onlineWork, true);
      expect(entity.status, LogStatus.early);
    });

    test('toDto should map correctly', () {
      final entity = LogEntry(
        id: 1,
        date: DateTime.parse('2023-01-01T12:00:00Z'),
        bonusTime: const Duration(minutes: -5),
        userEdited: false,
        clockedInTime: DateTime.parse('2023-01-01T08:00:00Z'),
        clockedOutTime: DateTime.parse('2023-01-01T15:55:00Z'),
        onlineWork: false,
      );

      final dto = LogMapper.toDto(entity);

      expect(dto.id, 1);
      expect(dto.dateAdded, '2023-01-01T12:00:00.000Z');
      expect(dto.bonusTime, -5);
      expect(dto.userEdited, 0);
      expect(dto.clockedInTime, '2023-01-01T08:00:00.000Z');
      expect(dto.clockedOutTime, '2023-01-01T15:55:00.000Z');
      expect(dto.onlineWork, 0);
      expect(dto.vacation, 0);
    });

    test('vacation round-trips through the DTO', () {
      final entity = LogEntry(
        date: DateTime.parse('2023-01-01T00:00:00Z'),
        bonusTime: Duration.zero,
        userEdited: true,
        onlineWork: false,
        vacation: true,
      );

      final dto = LogMapper.toDto(entity);
      expect(dto.vacation, 1);
      expect(dto.toMap()['vacation'], 1);
      expect(LogMapper.toEntity(dto).vacation, isTrue);
      expect(LogMapper.toEntity(dto).type, LogType.vacation);
    });

    test('rows from before the vacation column read as not vacation', () {
      final dto = LogDto.fromMap({
        'log_id': 1,
        'date_added': '2023-01-01T12:00:00Z',
        'bonus_time': 0,
        'user_edited': 0,
        'online_work': 0,
      });
      expect(dto.vacation, 0);
    });
  });
}

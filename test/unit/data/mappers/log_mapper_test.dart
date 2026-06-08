import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/data/dtos/log_dto.dart';
import 'package:clock_app/data/mappers/log_mapper.dart';
import 'package:clock_app/domain/entities/log_entry.dart';

void main() {
  group('LogMapper', () {
    test('fromDto should map correctly', () {
      final dto = LogDto(
        id: 1,
        dateAdded: '2023-01-01T12:00:00Z',
        bonusTime: '0',
        userEdited: 0,
        onlineWork: 0,
      );

      final entity = LogMapper.fromDto(dto);

      expect(entity.date, DateTime.parse('2023-01-01T12:00:00Z'));
      expect(entity.status, LogStatus.onTime);
      expect(entity.offset, Duration.zero);
    });

    test('toDto should map correctly', () {
      final entity = LogEntry(
        date: DateTime.parse('2023-01-01T12:00:00Z'),
        status: LogStatus.early,
        offset: const Duration(minutes: 30),
      );

      final dto = LogMapper.toDto(entity);

      expect(dto.dateAdded, '2023-01-01T12:00:00.000Z');
      expect(dto.bonusTime, '0');
      expect(dto.userEdited, 0);
      expect(dto.onlineWork, 0);
    });
  });
}

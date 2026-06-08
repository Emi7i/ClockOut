import '../../domain/entities/log_entry.dart';
import '../dtos/log_dto.dart';

class LogMapper {
  static LogEntry fromDto(LogDto dto) {
    // Logic for status/offset would go here. 
    // For now, mapping basic fields.
    return LogEntry(
      date:   DateTime.parse(dto.dateAdded),
      status: LogStatus.onTime, // Default for now
      offset: Duration.zero,    // Default for now
    );
  }

  static LogDto toDto(LogEntry entity) {
    return LogDto(
      dateAdded:  entity.date.toIso8601String(),
      bonusTime:  '0',
      userEdited: 0,
      onlineWork: 0,
    );
  }
}

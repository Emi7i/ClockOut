import '../../domain/entities/log_entry.dart';
import '../dtos/log_dto.dart';

class LogMapper {
  static LogEntry toEntity(LogDto dto) {
    return LogEntry(
      id:             dto.id,
      date:           DateTime.parse(dto.dateAdded),
      bonusTime:      Duration(minutes: dto.bonusTime),
      userEdited:     dto.userEdited == 1,
      clockedInTime:  dto.clockedInTime != null ? DateTime.parse(dto.clockedInTime!) : null,
      clockedOutTime: dto.clockedOutTime != null ? DateTime.parse(dto.clockedOutTime!) : null,
      onlineWork:     dto.onlineWork == 1,
    );
  }

  static LogDto toDto(LogEntry entity) {
    return LogDto(
      id:             entity.id,
      dateAdded:      entity.date.toIso8601String(),
      bonusTime:      entity.bonusTime.inMinutes,
      userEdited:     entity.userEdited ? 1 : 0,
      clockedInTime:  entity.clockedInTime?.toIso8601String(),
      clockedOutTime: entity.clockedOutTime?.toIso8601String(),
      onlineWork:     entity.onlineWork ? 1 : 0,
    );
  }
}

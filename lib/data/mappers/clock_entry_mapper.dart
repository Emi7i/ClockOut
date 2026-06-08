import '../../domain/entities/clock_entry.dart';
import '../dtos/log_dto.dart';

class ClockEntryMapper {
  static ClockEntry fromDto(LogDto dto) {
    return ClockEntry(
      id:           dto.id?.toString() ?? '',
      clockedInAt:  DateTime.parse(dto.clockedInTime ?? dto.dateAdded),
      clockedOutAt: dto.clockedOutTime != null 
          ? DateTime.fromMillisecondsSinceEpoch(dto.clockedOutTime!) 
          : null,
      alarmEnabled: false, // This would need to come from somewhere else or another DTO
    );
  }

  static LogDto toDto(ClockEntry entity) {
    return LogDto(
      id:               int.tryParse(entity.id),
      dateAdded:        entity.clockedInAt.toIso8601String(),
      clockedInTime:    entity.clockedInAt.toIso8601String(),
      clockedOutTime:   entity.clockedOutAt?.millisecondsSinceEpoch,
      bonusTime:        '0',
      userEdited:       0,
      onlineWork:       0,
    );
  }
}

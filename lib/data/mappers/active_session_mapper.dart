import '../../domain/entities/active_session.dart';
import '../dtos/active_session_dto.dart';

class ActiveSessionMapper {
  static ActiveSession toEntity(ActiveSessionDto dto) {
    return ActiveSession(
      clockedInAt:          DateTime.parse(dto.clockedInTime),
      nextAlarmIn:          dto.nextAlarmIn,
      accumulatedBonusTime: Duration(minutes: dto.accumulatedBonusTime),
      alarmEnabled:         dto.alarmOn == 1,
    );
  }

  static ActiveSessionDto toDto(ActiveSession entity) {
    return ActiveSessionDto(
      clockedInTime:          entity.clockedInAt.toIso8601String(),
      nextAlarmIn:            entity.nextAlarmIn,
      accumulatedBonusTime:   entity.accumulatedBonusTime.inMinutes,
      alarmOn:                entity.alarmEnabled ? 1 : 0,
    );
  }
}

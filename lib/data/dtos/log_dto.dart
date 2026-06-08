/// ─────────────────────────────────────────────────────────────
///  LOG DTO
///  Data Transfer Object for the Logs table in SQLite.
/// ─────────────────────────────────────────────────────────────
class LogDto {
  final int? id;
  final String dateAdded;
  final String bonusTime;
  final int userEdited; // 0 or 1
  final String? clockedInTime;
  final int? clockedOutTime;
  final int onlineWork;

  const LogDto({
    this.id,
    required this.dateAdded,
    required this.bonusTime,
    required this.userEdited,
    this.clockedInTime,
    this.clockedOutTime,
    required this.onlineWork,
  });

  /// Convert from Map (SQLite result)
  factory LogDto.fromMap(Map<String, dynamic> map) {
    return LogDto(
      id:             map['log_id'] as int?,
      dateAdded:      map['date_added'] as String,
      bonusTime:      map['bonus_time'] as String,
      userEdited:     map['user_edited'] as int,
      clockedInTime:  map['clocked_in_time'] as String?,
      clockedOutTime: map['clocked_out_time'] as int?,
      onlineWork:     map['online_work'] as int,
    );
  }

  /// Convert to Map for insertion/update
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'log_id': id,
      'date_added':       dateAdded,
      'bonus_time':       bonusTime,
      'user_edited':      userEdited,
      'clocked_in_time':  clockedInTime,
      'clocked_out_time': clockedOutTime,
      'online_work':      onlineWork,
    };
  }
}

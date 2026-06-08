/// ─────────────────────────────────────────────────────────────
///  CLOCK ENTRY  –  Domain Entity
///  Represents a single clock-in / clock-out session.
///  Plain Dart: no framework dependencies.
/// ─────────────────────────────────────────────────────────────
class ClockEntry {
  final String   id;
  final DateTime clockedInAt;
  final DateTime? clockedOutAt;
  final bool     alarmEnabled;

  const ClockEntry({
    required this.id,
    required this.clockedInAt,
    this.clockedOutAt,
    this.alarmEnabled = false,
  });

  bool get isClockedIn => clockedOutAt == null;

  Duration get elapsed {
    final end = clockedOutAt ?? DateTime.now();
    return end.difference(clockedInAt);
  }

  ClockEntry copyWith({
    DateTime? clockedOutAt,
    bool? alarmEnabled,
  }) {
    return ClockEntry(
      id: id,
      clockedInAt: clockedInAt,
      clockedOutAt: clockedOutAt ?? this.clockedOutAt,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    );
  }
}

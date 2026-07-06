import '../entities/active_session.dart';
import '../repositories/active_session_repository.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK IN USE CASE
///  Single-responsibility: starts a new session.
/// ─────────────────────────────────────────────────────────────
class ClockInUseCase {
  final ActiveSessionRepository _repository;

  const ClockInUseCase(this._repository);

  Future<ActiveSession> call({bool alarmEnabled = false}) =>
      _repository.clockIn(alarmEnabled: alarmEnabled);
}

import '../entities/active_session.dart';
import '../repositories/active_session_repository.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK OUT USE CASE
/// ─────────────────────────────────────────────────────────────
class ClockOutUseCase {
  final ActiveSessionRepository _repository;

  const ClockOutUseCase(this._repository);

  Future<ActiveSession> call() => _repository.clockOut();
}

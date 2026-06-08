import '../entities/clock_entry.dart';
import '../repositories/clock_repository.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK IN USE CASE
///  Single-responsibility: starts a new session.
/// ─────────────────────────────────────────────────────────────
class ClockInUseCase {
  final ClockRepository _repository;

  const ClockInUseCase(this._repository);

  Future<ClockEntry> call() => _repository.clockIn();
}

import '../entities/clock_entry.dart';
import '../repositories/clock_repository.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK OUT USE CASE
/// ─────────────────────────────────────────────────────────────
class ClockOutUseCase {
  final ClockRepository _repository;

  const ClockOutUseCase(this._repository);

  Future<ClockEntry> call() => _repository.clockOut();
}

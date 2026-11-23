import '../../domain/entities/log_entry.dart';

/// ─────────────────────────────────────────────────────────────
///  CAT ASSETS
///  Picks the cat illustration for a log. There is one log per day.
///
///    vacation            → Vacation cat      (added manually, no clock times)
///    remote work         → Remote work cat   (counted as 8h, added manually)
///    bonus time          → Bonus time cat    (30+ min past the shift)
///    left early          → Early leave cat   (any time short of the shift)
///    anything else       → Worker cat        (a normal 8h shift; under 30
///                                             min over adds no bonus)
/// ─────────────────────────────────────────────────────────────
abstract final class CatAssets {
  /// Every cat comes in a light and a dark variant.
  /// TODO: choose by theme once light mode exists — only dark is used for now.
  static const String _variant = '_dark';

  static const String _dir = 'assets/cats';
  static const String remoteWork = '$_dir/remote_work_cat$_variant.svg';
  static const String bonusTime = '$_dir/bonus_time_cat$_variant.svg';
  static const String earlyLeave = '$_dir/early_leave_cat$_variant.svg';
  static const String worker = '$_dir/worker_cat$_variant.svg';

  /// TODO: placeholder art — replace `vacation_cat*.svg` with the real cat.
  static const String vacation = '$_dir/vacation_cat$_variant.svg';

  static String forLog(LogEntry log) {
    switch (log.type) {
      case LogType.vacation:
        return vacation;
      case LogType.remote:
        return remoteWork;
      case LogType.normal:
        return switch (log.status) {
          LogStatus.early => bonusTime,
          LogStatus.late => earlyLeave,
          LogStatus.onTime => worker,
        };
    }
  }
}

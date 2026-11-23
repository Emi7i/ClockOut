import '../../domain/entities/log_entry.dart';

/// ─────────────────────────────────────────────────────────────
///  CAT ASSETS
///  Maps a day's log status to its cat illustration.
///  TODO: swap the placeholder for the real cat SVGs in assets/cats/.
/// ─────────────────────────────────────────────────────────────
abstract final class CatAssets {
  static const String _placeholder = 'assets/cats/placeholder.svg';

  static String forStatus(LogStatus status) => switch (status) {
        LogStatus.onTime => _placeholder,
        LogStatus.early => _placeholder,
        LogStatus.late => _placeholder,
      };
}

import '../entities/user_settings.dart';

/// ─────────────────────────────────────────────────────────────
///  USER SETTINGS REPOSITORY  –  Abstract Contract
/// ─────────────────────────────────────────────────────────────
abstract interface class UserSettingsRepository {
  /// Fetches the current user settings.
  Future<UserSettings> getSettings();

  /// Updates the user settings.
  Future<void> updateSettings(UserSettings settings);
}

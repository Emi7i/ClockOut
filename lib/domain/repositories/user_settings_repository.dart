import '../entities/user_settings.dart';

/// ─────────────────────────────────────────────────────────────
///  USER SETTINGS REPOSITORY  –  Abstract Contract
/// ─────────────────────────────────────────────────────────────
abstract interface class UserSettingsRepository {
  static late UserSettingsRepository Function() build;

  /// Fetches the current user settings.
  Future<UserSettings> getSettings();

  /// Updates the user settings.
  Future<void> updateSettings(UserSettings settings);
}

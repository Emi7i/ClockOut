import '../entities/active_session.dart';

/// ─────────────────────────────────────────────────────────────
///  ACTIVE SESSION REPOSITORY  –  Abstract Contract (Domain Layer)
///  The data layer must implement this interface.
///  Features depend only on this abstraction, never on the impl.
/// ─────────────────────────────────────────────────────────────
abstract interface class ActiveSessionRepository {
  /// Static factory to build the implementation.
  /// Must be initialized in main() and background entry points.
  static late ActiveSessionRepository Function() build;

  /// Returns the active session, or null if not clocked in.
  Future<ActiveSession?> getActiveSession();

  /// Starts a new clock-in session.
  Future<ActiveSession> clockIn();

  /// Ends the active session.
  Future<ActiveSession> clockOut();

  /// Updates the entire active session state.
  Future<void> updateActiveSession(ActiveSession session);

  /// Toggles the alarm for the active session.
  Future<void> setAlarmSound({required bool enabled});

  /// Updates the clock-in time for the currently active session.
  Future<void> updateActiveClockInTime(DateTime newTime);
}

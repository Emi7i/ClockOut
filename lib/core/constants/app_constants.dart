class AppConstants {
  static const String appName = 'ClockOut';
  static const String dbName = 'clockout_database.db';
  static const int dbVersion = 3;

  /// Standard shift length. Single source of truth for both alarm
  /// scheduling (ClockBloc) and log bonus-time calculation.
  // Debug
  //static const Duration shiftDuration = Duration(seconds: 30);
  static const Duration shiftDuration = Duration(hours: 8);

  /// Length of the Figma Day→Night timeline (1.39559 s). The scene
  /// controller's 0..1 value maps linearly onto it.
  static const Duration sceneDuration = Duration(milliseconds: 1396);

  /// Progress past which releasing a swipe always finishes the transition
  /// (about where the Earth is almost gone). Tuned on device in phase 3.
  static const double sceneCommitPoint = 0.58;

  /// A full Day↔Night swipe needs this fraction of the screen height.
  static const double sceneTravelFraction = 0.5;

  /// Per-event vertical movement (px) below which it is jitter and does not
  /// count as a change of direction.
  static const double sceneMinDirectionDelta = 1.0;
}

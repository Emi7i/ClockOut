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

  /// Vertical swipe distance (px, after the touch slop) that counts as a
  /// deliberate swipe. Only the direction matters, not speed or length.
  static const double sceneSwipeMinDistance = 24;
}

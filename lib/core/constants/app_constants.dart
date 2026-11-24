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

  /// Length of the Figma "Start Shift" UFO timeline (3 s). Played once,
  /// forward, when a shift starts.
  static const Duration shiftIntroDuration = Duration(seconds: 3);

  /// How fast the dashed ring turns, in full turns per second. Decorative
  /// only; it is not tied to the shift timer.
  static const double ringTurnsPerSecond = 0.02;

  /// Debug builds only: fast-forward for the UFO's orbit. 960 makes an 8 h
  /// shift take 30 s. Toggled from the debug strip on the home screen.
  static const double debugTimeScale = 960;

  /// Opacity of the dashed ring once it has faded in: 0 = invisible,
  /// 1 = solid white. Change it here.
  static const double ringOpacity = 0.34;

  /// Vertical swipe distance (px, after the touch slop) that counts as a
  /// deliberate swipe. Only the direction matters, not speed or length.
  static const double sceneSwipeMinDistance = 24;
}

class AppConstants {
  static const String appName = 'ClockOut';
  static const String dbName = 'clockout_database.db';
  static const int dbVersion = 1;

  /// Standard shift length. Single source of truth for both alarm
  /// scheduling (ClockBloc) and log bonus-time calculation.
  // Debug
  //static const Duration shiftDuration = Duration(seconds: 30);
  static const Duration shiftDuration = Duration(hours: 8);
}

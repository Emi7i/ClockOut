part of 'clock_bloc.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK STATES
/// ─────────────────────────────────────────────────────────────
sealed class ClockState {
  const ClockState();
}

/// Initial load in progress.
final class ClockLoading extends ClockState {
  const ClockLoading();
}

/// Not clocked in – shows the Clock In screen.
final class ClockIdle extends ClockState {
  final DateTime currentTime;
  final bool alarmEnabled;

  const ClockIdle({
    required this.currentTime,
    this.alarmEnabled = false,
  });
}

/// Actively clocked in – shows the Clocked In screen.
final class ClockActive extends ClockState {
  final DateTime currentTime;
  final DateTime clockedInAt;
  final Duration remaining;     // time until end-of-shift
  final bool alarmEnabled;
  final Duration? nextAlarmIn;  // null when alarm is off

  const ClockActive({
    required this.currentTime,
    required this.clockedInAt,
    required this.remaining,
    this.alarmEnabled  = false,
    this.nextAlarmIn,
  });
}

/// An error occurred.
final class ClockError extends ClockState {
  final String message;
  const ClockError(this.message);
}

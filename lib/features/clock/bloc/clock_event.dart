part of 'clock_bloc.dart';

/// ─────────────────────────────────────────────────────────────
///  CLOCK EVENTS
///  Add a new user action by creating a new [ClockEvent] subclass.
/// ─────────────────────────────────────────────────────────────
sealed class ClockEvent {
  const ClockEvent();
}

/// App started or screen resumed – load current session state.
final class ClockStarted extends ClockEvent {
  const ClockStarted();
}

/// User tapped the Clock In oval button.
final class ClockInRequested extends ClockEvent {
  const ClockInRequested();
}

/// User tapped the Clock Out oval button.
final class ClockOutRequested extends ClockEvent {
  const ClockOutRequested();
}

/// User toggled the alarm switch.
final class AlarmToggled extends ClockEvent {
  final bool enabled;
  const AlarmToggled({required this.enabled});
}

/// Periodic tick emitted every second while clocked in.
final class ClockTicked extends ClockEvent {
  const ClockTicked();
}

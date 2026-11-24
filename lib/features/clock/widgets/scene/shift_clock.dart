import '../../../../core/constants/constants.dart';

/// Where the UFO is along its orbit, from the persisted clock-in time.
///
/// Nothing here is animated or remembered in memory: the position is always
/// computed from the clock, so it is right on every frame and straight after
/// an app resume or restart.
///
/// Returns 0 (left end) when the shift starts and 1 (mirrored point on the
/// right) once [shiftLength] has passed; it stays at 1 until the user
/// clocks out.
///
/// [timeScale] > 1 is the debug fast-forward (an 8 h shift in seconds).
/// [startOffset] is real time subtracted from the elapsed time first. It is
/// only used with the debug scale, so the UFO does not jump when the 3 s
/// intro hands over to the orbit.
double shiftOrbitFraction({
  required DateTime clockedInAt,
  required DateTime now,
  double timeScale = 1,
  Duration startOffset = Duration.zero,
  Duration shiftLength = AppConstants.shiftDuration,
}) {
  final elapsed = now.difference(clockedInAt) - startOffset;
  final scaled = elapsed.inMicroseconds * timeScale;
  return (scaled / shiftLength.inMicroseconds).clamp(0.0, 1.0);
}

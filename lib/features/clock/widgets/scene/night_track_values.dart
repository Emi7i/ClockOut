import '../../../../domain/tracks/bonus_track.dart';
import '../../../../domain/tracks/remote_track.dart';
import '../../../../domain/tracks/vacation_track.dart';

/// The three bodies of the Night scene.
enum NightBody { vacation, remote, bonus }

/// The stats behind the Night bodies.
///
/// The comets travel as allowances are USED UP (start = all still there,
/// end = all used); the moon travels as bonus hours are EARNED. Each status
/// comes from a conversion in `lib/domain/tracks/`; its `progress` (0..1) is
/// where the body sits on its orbit, and the rest feeds the readout.
class NightTrackValues {
  /// Top comet: the year's vacation days.
  final VacationStatus vacation;

  /// Lower comet: the weekly remote day.
  final RemoteStatus remote;

  /// Moon: bonus hours' progress to the next vacation day.
  final BonusStatus bonus;

  const NightTrackValues({
    required this.vacation,
    required this.remote,
    required this.bonus,
  });

  /// Where [body] sits on its orbit, 0 (start) … 1 (end).
  double progressOf(NightBody body) => switch (body) {
        NightBody.vacation => vacation.progress,
        NightBody.remote => remote.progress,
        NightBody.bonus => bonus.progress,
      };
}

import '../../core/constants/app_constants.dart';

/// Where the user stands on the vacation track.
///
/// The comet travels as days are used up: the solid line behind it is what
/// has been taken, the dashed line ahead is what is still there.
class VacationStatus {
  /// Days the user can take this year: the yearly allowance plus every day
  /// converted from bonus hours so far.
  final int daysAvailable;

  /// Days not yet taken.
  final int daysLeft;

  const VacationStatus({required this.daysAvailable, required this.daysLeft});

  /// 0 (nothing taken yet) … 1 (every day taken): the share already used,
  /// `1 - days left / days available`.
  double get progress => daysAvailable <= 0
      ? 1
      : (1 - daysLeft / daysAvailable).clamp(0.0, 1.0);
}

/// Vacation: [annualDays] a year, and bonus hours can be converted into extra
/// days, so days available = [annualDays] + [convertedDays].
/// Progress = the share used = 1 - days left / days available.
VacationStatus vacationStatus({
  required int usedDays,
  required int convertedDays,
  int annualDays = AppConstants.annualVacationDays,
}) {
  final available = annualDays + convertedDays;
  final left = (available - usedDays).clamp(0, available);
  return VacationStatus(daysAvailable: available, daysLeft: left);
}

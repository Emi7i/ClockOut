import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';

/// ─────────────────────────────────────────────────────────────
///  APP TEXT STYLES
///  All typography in one place.
///  To swap fonts: change [_font] / [_titleFont] and update pubspec.yaml.
/// ─────────────────────────────────────────────────────────────
abstract final class AppTextStyles {
  /// ← swap font family here
  static const String _font = 'Roboto';

  /// Display font for titles and big text (e.g. the calendar's month/year).
  static const String _titleFont = 'Iceland';

  // ── Home scene (redesign) ─────────────────────────────────
  /// "Start Shift" on the Day card.
  static const TextStyle startShift = TextStyle(
    fontFamily: _titleFont,
    fontSize: 48,
    height: 1.2,
    letterSpacing: 0.48,
    color: Color(0xFFFFFFFF),
  );

  /// Short label under a Night body (Vacation / Remote / Bonus).
  static const TextStyle trackLabel = TextStyle(
    decoration: TextDecoration.none,
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: Color(0xCCFFFFFF),
  );

  /// Small caps title of the Night readout (the selected body's name).
  static const TextStyle readoutTitle = TextStyle(
    decoration: TextDecoration.none,
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.4,
    color: Color(0xB3FFFFFF),
  );

  /// The Night readout's value, e.g. "14 of 22 left" (same face as Start Shift).
  static const TextStyle readoutValue = TextStyle(
    decoration: TextDecoration.none,
    fontFamily: _titleFont,
    fontSize: 26,
    height: 1.2,
    letterSpacing: 0.3,
    color: Color(0xFFFFFFFF),
  );

  /// The Convert button's label (same face as Start Shift).
  static const TextStyle convertButton = TextStyle(
    decoration: TextDecoration.none,
    fontFamily: _titleFont,
    fontSize: 22,
    height: 1.2,
    letterSpacing: 0.3,
    color: Color(0xFFFFFFFF),
  );

  // ── Calendar (redesign) ───────────────────────────────────
  /// Month and year. Iceland only ships a regular weight.
  static const TextStyle calendarTitle = TextStyle(
    fontFamily: _titleFont,
    fontSize: 28,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle calendarWeekday = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.calendarTextSecondary,
  );

  static const TextStyle calendarDay = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.calendarText,
  );

  // ── Add log popup ─────────────────────────────────────────
  static const TextStyle popupTitle = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle popupLabel = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    color: AppColors.textPrimary,
  );

  static const TextStyle popupButton = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    color: AppColors.textPrimary,
  );

  static const TextStyle agendaHeader = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    color: AppColors.calendarText,
  );

  static const TextStyle agendaEmpty = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    color: AppColors.calendarText,
  );

  static const TextStyle agendaEventTitle = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle agendaEventDetail = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    color: AppColors.calendarTextSecondary,
  );

  // ── Display ───────────────────────────────────────────────
  static const TextStyle timeDisplay = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Oval button label ─────────────────────────────────────
  static const TextStyle ovalButton = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Remaining countdown ───────────────────────────────────
  static const TextStyle remainingLarge = TextStyle(
    fontFamily: _font,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );

  static const TextStyle remainingSmall = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    color: AppColors.accent,
  );

  // ── Body ──────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    color: AppColors.textMuted,
  );

  // ── Labels ────────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    color: AppColors.textSecondary,
  );

  static const TextStyle alarmSubtext = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    color: AppColors.textMuted,
  );

  // ── Log list ──────────────────────────────────────────────
  static const TextStyle logNeutral = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    color: AppColors.textSecondary,
  );

  static const TextStyle logPositive = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    color: AppColors.positive,
  );

  static const TextStyle logNegative = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    color: AppColors.negative,
  );

  // ── Settings ──────────────────────────────────────────────
  static const TextStyle settingLabel = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    color: AppColors.textSecondary,
  );

  // ── Donut chart ───────────────────────────────────────────
  static const TextStyle donutPrimary = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    color: AppColors.textSecondary,
  );

  static const TextStyle donutSecondary = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    color: AppColors.textMuted,
  );

  // ── Buttons ───────────────────────────────────────────────
  static const TextStyle outlineButton = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    color: AppColors.textSecondary,
  );

  static const TextStyle destructiveButton = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    color: AppColors.negative,
  );

  static const TextStyle chipButton = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.background,
  );
}

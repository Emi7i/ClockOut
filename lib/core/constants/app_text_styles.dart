import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ─────────────────────────────────────────────────────────────
///  APP TEXT STYLES
///  All typography in one place.
///  To swap font: change [_font] and update pubspec.yaml.
/// ─────────────────────────────────────────────────────────────
abstract final class AppTextStyles {
  /// ← swap font family here
  static const String _font = 'Caveat';

  // ── Display ───────────────────────────────────────────────
  static const TextStyle timeDisplay = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: _font,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Oval button label ─────────────────────────────────────
  static const TextStyle ovalButton = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Remaining countdown ───────────────────────────────────
  static const TextStyle remainingLarge = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );

  static const TextStyle remainingSmall = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    color: AppColors.accent,
  );

  // ── Body ──────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 17,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    color: AppColors.textMuted,
  );

  // ── Labels ────────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    color: AppColors.textSecondary,
  );

  static const TextStyle alarmSubtext = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    color: AppColors.textMuted,
  );

  // ── Log list ──────────────────────────────────────────────
  static const TextStyle logNeutral = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    color: AppColors.textSecondary,
  );

  static const TextStyle logPositive = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    color: AppColors.positive,
  );

  static const TextStyle logNegative = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    color: AppColors.negative,
  );

  // ── Settings ──────────────────────────────────────────────
  static const TextStyle settingLabel = TextStyle(
    fontFamily: _font,
    fontSize: 17,
    color: AppColors.textSecondary,
  );

  // ── Donut chart ───────────────────────────────────────────
  static const TextStyle donutPrimary = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    color: AppColors.textSecondary,
  );

  static const TextStyle donutSecondary = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    color: AppColors.textMuted,
  );

  // ── Buttons ───────────────────────────────────────────────
  static const TextStyle outlineButton = TextStyle(
    fontFamily: _font,
    fontSize: 17,
    color: AppColors.textSecondary,
  );

  static const TextStyle destructiveButton = TextStyle(
    fontFamily: _font,
    fontSize: 17,
    color: AppColors.negative,
  );

  static const TextStyle chipButton = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.background,
  );
}

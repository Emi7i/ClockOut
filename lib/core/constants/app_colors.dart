import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
///  APP COLORS
///  Single source of truth for every color in the app.
///  To retheme: change values here — nothing else needs editing.
/// ─────────────────────────────────────────────────────────────
abstract final class AppColors {
  // ── Backgrounds ───────────────────────────────────────────
  /// Main screen background (near-black)
  static const Color background = Color(0xFF1E1E1E);

  /// Bottom navigation bar background
  static const Color navBar = Color(0xFF343A40);

  /// Surface used for cards, list containers
  static const Color surface = Color(0xFF343A40);

  // ── Accent ────────────────────────────────────────────────
  /// Primary neon yellow-green accent
  static const Color accent = Color(0xFFC8F000);

  /// Accent at ~16 % opacity (used for icon-box fills)
  static const Color accentDim = Color(0x28C8F000);

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted     = Color(0xFF888888);

  // ── Semantic ──────────────────────────────────────────────
  /// Positive log entries (early / overtime)
  static const Color positive = Color(0xFFC8F000);

  /// Negative log entries (late) and destructive actions
  static const Color negative = Color(0xFFE06060);

  /// Default border colour
  static const Color border = Color(0xFF3A3A3A);

  /// Dashed / muted border colour
  static const Color borderDashed = Color(0xFF888888);

  // ── Toggle ────────────────────────────────────────────────
  static const Color toggleOff = Colors.transparent;
  static const Color toggleOn  = Color(0xFFC8F000);
}

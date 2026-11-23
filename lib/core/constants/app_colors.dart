import 'package:material_ui/material_ui.dart';

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
  /// Default accent before user settings load, or if the user has never
  /// picked a colour. The live accent is `Theme.of(context).colorScheme
  /// .primary`, driven by SettingsBloc — see main.dart.
  static const Color accent = Color(0xFFC8F000);

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

  // ── Calendar (redesign) ───────────────────────────────────
  /// Calendar screen background
  static const Color calendarBackground = Color(0xFF1C1C1D);

  /// Agenda section header strip
  static const Color agendaHeader = Color(0xFF1E1E1E);

  /// Agenda event / "No event" row
  static const Color agendaRow = Color(0xFF000000);

  /// Primary text on calendar rows
  static const Color calendarText = Color(0xFFEDEDED);

  /// Secondary text on calendar rows (clock in/out times)
  static const Color calendarTextSecondary = Color(0xFFBCBCBC);

  /// Bonus amount highlight
  static const Color bonus = Color(0xFF2AB26E);

  /// Ring around the cat of a vacation paid from the time bank.
  static const Color bankRing = Color(0xFFB22A7C);

  // ── Add log popup (redesign) ──────────────────────────────
  /// Input fields and the slider track
  static const Color popupField = Color(0xFF3B3B3B);

  /// "Cancel" button
  static const Color popupCancel = Color(0xFF2F2F31);

  // ── Toggle ────────────────────────────────────────────────
  static const Color toggleOff = Colors.transparent;
}

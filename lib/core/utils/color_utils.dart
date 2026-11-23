import 'package:material_ui/material_ui.dart';

extension ColorShade on Color {
  /// This color made darker by [amount] (0–1) of its lightness, keeping the
  /// hue. Used to derive gradient ends from the user's accent color.
  Color darken(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0))
        .toColor();
  }
}

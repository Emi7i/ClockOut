import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
///  ADD BUTTON
///  Dark-grey rounded square with an accent border and accent "+".
///  [turns] rotates the "+" (0.125 = 45°, i.e. an "x").
/// ─────────────────────────────────────────────────────────────
class AddButton extends StatelessWidget {
  final double       turns;
  final VoidCallback onTap;
  final double       size;

  const AddButton({
    super.key,
    required this.turns,
    required this.onTap,
    this.size = 62,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      label: 'Add',
      child: Material(
        color: const Color(0xFF2B2D30),
        elevation: 6,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: color, width: 2.5),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: SizedBox(
            width: size,
            height: size,
            child: Transform.rotate(
              angle: turns * 2 * math.pi,
              child: Icon(Icons.add_rounded, size: 36, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

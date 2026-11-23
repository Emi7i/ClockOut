import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/utils/color_utils.dart';

/// The floating "+" button. Only the plus rotates (by [turns]); the frame
/// stays put.
class AddLogButton extends StatelessWidget {
  /// Rotation of the plus, in full turns (0.625 = 180° + 45° = 225°).
  final Animation<double> turns;
  final VoidCallback onTap;

  const AddLogButton({super.key, required this.turns, required this.onTap});

  static const double size = 75;
  static const double _border = 5;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(_border),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.5),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent, accent.darken(0.5)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.5),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF232323), Color(0xFF050505), Color(0xFF000000)],
              stops: [0, 0.43, 1],
            ),
          ),
          child: Center(
            child: RotationTransition(
              turns: turns,
              child: SvgPicture.asset(
                'assets/icons/add_plus.svg',
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

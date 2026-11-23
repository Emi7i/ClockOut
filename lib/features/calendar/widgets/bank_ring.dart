import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';

/// A circle around a cat, marking a vacation paid from the time bank.
/// With [active] false the [child] is returned untouched.
///
/// The ring is drawn *outside* the child's box, so the cat keeps exactly the
/// size it has without a ring. Leave [reach] of free room around it.
class BankRing extends StatelessWidget {
  final bool active;
  final Widget child;

  static const double thickness = 2;

  /// Space between the cat and the ring.
  static const double gap = 2;

  /// How far the ring extends past the child's box on every side.
  static const double reach = gap + thickness;

  const BankRing({super.key, required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: -reach,
          top: -reach,
          right: -reach,
          bottom: -reach,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bankRing, width: thickness),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';

/// Drag handle below the calendar. Drag up to condense, down to expand;
/// tap to toggle.
class CalendarHandle extends StatelessWidget {
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onTap;

  const CalendarHandle({
    super.key,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  static const double height = 24;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

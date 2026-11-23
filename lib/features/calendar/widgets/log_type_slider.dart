import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/color_utils.dart';
import '../../../domain/entities/log_entry.dart';

/// Three-way selector (Normal / Remote / Vacation) with a gradient thumb.
///
/// The thumb only ever rests on one of the three keypoints. Tapping a
/// segment slides it there; dragging across the track moves it to whichever
/// segment the finger is over.
class LogTypeSlider extends StatelessWidget {
  final LogType selected;
  final ValueChanged<LogType> onChanged;

  const LogTypeSlider({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const double width = 169;
  static const double height = 25;

  /// Thumb width relative to the track's inner width (58 of 167 in Figma).
  static const double _thumbFraction = 58 / 167;

  static const Map<LogType, String> _labels = {
    LogType.normal: 'Normal',
    LogType.remote: 'Remote',
    LogType.vacation: 'Vacation',
  };

  static const Duration _slide = Duration(milliseconds: 250);

  void _onDrag(double dx) {
    final index = (dx / width * LogType.values.length)
        .floor()
        .clamp(0, LogType.values.length - 1);
    final type = LogType.values[index];
    if (type != selected) onChanged(type);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onHorizontalDragUpdate: (d) => _onDrag(d.localPosition.dx),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: AppColors.popupField,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            // Thumb: alignment -1 / 0 / 1 puts it on the left, middle, right
            // keypoint, evenly spaced across the track.
            AnimatedAlign(
              duration: _slide,
              curve: Curves.easeInOut,
              alignment: Alignment(selected.index - 1.0, 0),
              child: FractionallySizedBox(
                widthFactor: _thumbFraction,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, accent.darken(0.5)],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final type in LogType.values)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(type),
                      child: Center(
                        child: Text(
                          _labels[type]!,
                          style: AppTextStyles.popupLabel,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/log_entry.dart';
import '../cat_assets.dart';

/// One day in the month grid.
///
/// The cat slot is an [Expanded] child, so the space above the number is
/// always reserved — whether or not the day has a cat to show.
class DayCell extends StatelessWidget {
  final DateTime day;
  final bool isInVisibleMonth;
  final bool isToday;
  final bool isSelected;

  /// Status of the day's logs; `null` when there are none (no cat shown).
  final LogStatus? status;
  final VoidCallback onTap;

  const DayCell({
    super.key,
    required this.day,
    required this.isInVisibleMonth,
    required this.isToday,
    required this.isSelected,
    required this.status,
    required this.onTap,
  });

  static const double _numberSize = 26;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
              child: status == null
                  ? null
                  : Opacity(
                      opacity: isInVisibleMonth ? 1 : 0.4,
                      child: SvgPicture.asset(CatAssets.forStatus(status!)),
                    ),
            ),
          ),
          Container(
            width: _numberSize,
            height: _numberSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? accent : null,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: accent, width: 1.2)
                  : null,
            ),
            child: Text(
              '${day.day}',
              style: AppTextStyles.calendarDay.copyWith(
                color: isSelected
                    ? AppColors.background
                    : isInVisibleMonth
                        ? AppColors.calendarText
                        : AppColors.textMuted,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

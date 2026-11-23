import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';

/// Month title with a collapse chevron, plus the overflow menu button.
class CalendarHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback? onMoreTap;

  const CalendarHeader({super.key, required this.month, this.onMoreTap});

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormatter.monthYear(month),
                style: AppTextStyles.calendarTitle.copyWith(color: accent),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                'assets/icons/collapse_month.svg',
                width: 12,
                height: 12,
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
              ),
            ],
          ),
          Positioned(
            right: 3,
            child: IconButton(
              onPressed: onMoreTap,
              icon: SvgPicture.asset(
                'assets/icons/more_options.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.calendarText,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

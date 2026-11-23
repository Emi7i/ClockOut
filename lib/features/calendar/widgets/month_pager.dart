import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/month_grid.dart';
import '../bloc/calendar_bloc.dart';
import 'day_cell.dart';
import 'sensitive_page_physics.dart';

/// Horizontally swipeable months, Sunday–Saturday.
///
/// [expansion] runs from 1 (whole month) to 0 (only the selected week).
class MonthPager extends StatefulWidget {
  final Animation<double> expansion;

  const MonthPager({super.key, required this.expansion});

  /// Height of one week row. Leaves room for a cat above each number.
  static const double rowHeight = 68;
  static const double weekdayLabelsHeight = 28;

  /// Pager height for [weeks] rows at [expansion] (0–1).
  static double heightFor(double weeks, double expansion) =>
      weekdayLabelsHeight + rowHeight + (weeks - 1) * rowHeight * expansion;

  @override
  State<MonthPager> createState() => _MonthPagerState();
}

class _MonthPagerState extends State<MonthPager> {
  /// Page the pager starts on; months are offsets from [_baseMonth].
  static const int _initialPage = 1200;

  late final DateTime _baseMonth;
  late final PageController _controller;

  /// Page the current drag began on (read by the snap physics).
  int _dragStartPage = _initialPage;

  @override
  void initState() {
    super.initState();
    _baseMonth = context.read<CalendarBloc>().state.visibleMonth;
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) =>
      MonthGrid.shiftMonth(_baseMonth, page - _initialPage);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (n) {
        if (n.dragDetails != null) _dragStartPage = _controller.page!.round();
        return false;
      },
      child: PageView.builder(
        controller: _controller,
        pageSnapping: false, // snapping handled by SensitivePagePhysics
        physics: SensitivePagePhysics(startPage: () => _dragStartPage),
        onPageChanged: (page) => context
            .read<CalendarBloc>()
            .add(CalendarMonthChanged(_monthForPage(page))),
        itemBuilder: (_, page) => _MonthPage(
          month: _monthForPage(page),
          expansion: widget.expansion,
        ),
      ),
    );
  }
}

class _MonthPage extends StatelessWidget {
  final DateTime month;
  final Animation<double> expansion;

  const _MonthPage({required this.month, required this.expansion});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CalendarBloc>().state;
    final days = MonthGrid.daysFor(month);
    final today = MonthGrid.dateOnly(DateTime.now());

    final weeks = [
      for (var i = 0; i < days.length; i += MonthGrid.daysPerWeek)
        days.sublist(i, i + MonthGrid.daysPerWeek),
    ];

    // The week kept in view when condensed: the selected one, if shown here.
    final focusedWeek = weeks
        .indexWhere((w) => w.any((d) => MonthGrid.isSameDay(d, state.selectedDay)))
        .clamp(0, weeks.length - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          const _WeekdayLabels(),
          Expanded(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: 0,
                maxHeight: weeks.length * MonthPager.rowHeight,
                child: AnimatedBuilder(
                  animation: expansion,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      0,
                      -focusedWeek * MonthPager.rowHeight * (1 - expansion.value),
                    ),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      for (final week in weeks)
                        SizedBox(
                          height: MonthPager.rowHeight,
                          child: Row(
                            children: [
                              for (final day in week)
                                Expanded(
                                  child: DayCell(
                                    day: day,
                                    isInVisibleMonth: day.month == month.month,
                                    isToday: MonthGrid.isSameDay(day, today),
                                    isSelected: MonthGrid.isSameDay(
                                        day, state.selectedDay),
                                    catAsset: state.catOn(day),
                                    onTap: () => context
                                        .read<CalendarBloc>()
                                        .add(CalendarDaySelected(day)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MonthPager.weekdayLabelsHeight,
      child: Row(
        children: [
          for (final label in DateFormatter.weekdayInitials)
            Expanded(
              child: Center(
                child: Text(label, style: AppTextStyles.calendarWeekday),
              ),
            ),
        ],
      ),
    );
  }
}

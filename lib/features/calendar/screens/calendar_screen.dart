import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/month_grid.dart';
import '../bloc/calendar_bloc.dart';
import '../widgets/calendar_handle.dart';
import '../widgets/calendar_header.dart';
import '../widgets/daily_agenda.dart';
import '../widgets/month_pager.dart';

/// Month calendar (swipe to change month, drag the handle to condense it
/// to one week) with a scrollable agenda of logs below.
/// Expects a [CalendarBloc] above it in the tree.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  static const double _flingVelocity = 300;

  /// 1 = full month, 0 = a single week.
  late final AnimationController _expansion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1,
  );

  @override
  void dispose() {
    _expansion.dispose();
    super.dispose();
  }

  int get _visibleWeeks => MonthGrid.daysFor(
        context.read<CalendarBloc>().state.visibleMonth,
      ).length ~/
      MonthGrid.daysPerWeek;

  void _onDragUpdate(DragUpdateDetails details) {
    final travel = MonthPager.rowHeight * (_visibleWeeks - 1);
    _expansion.value += details.delta.dy / travel;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final expand = velocity.abs() > _flingVelocity
        ? velocity > 0
        : _expansion.value > 0.5;
    _expansion.animateTo(expand ? 1 : 0, curve: Curves.easeOut);
  }

  void _toggle() => _expansion.animateTo(_expansion.value > 0.5 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.calendarBackground,
      body: SafeArea(
        child: Column(
          children: [
            BlocSelector<CalendarBloc, CalendarState, DateTime>(
              selector: (s) => s.visibleMonth,
              builder: (_, month) => CalendarHeader(month: month),
            ),
            BlocSelector<CalendarBloc, CalendarState, int>(
              selector: (s) =>
                  MonthGrid.daysFor(s.visibleMonth).length ~/
                  MonthGrid.daysPerWeek,
              builder: (_, weeks) => TweenAnimationBuilder<double>(
                tween: Tween(end: weeks.toDouble()),
                duration: const Duration(milliseconds: 200),
                builder: (_, animatedWeeks, __) => AnimatedBuilder(
                  animation: _expansion,
                  builder: (_, child) => SizedBox(
                    height: MonthPager.heightFor(animatedWeeks, _expansion.value),
                    child: child,
                  ),
                  child: MonthPager(expansion: _expansion),
                ),
              ),
            ),
            CalendarHandle(
              onDragUpdate: _onDragUpdate,
              onDragEnd: _onDragEnd,
              onTap: _toggle,
            ),
            const Expanded(child: DailyAgenda()),
          ],
        ),
      ),
    );
  }
}

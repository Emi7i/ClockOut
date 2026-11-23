import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/utils/month_grid.dart';
import '../bloc/calendar_bloc.dart';
import 'agenda_section.dart';

/// Scrollable, date-ordered list of every day in the visible month (with or
/// without logs). Selecting a day in the calendar scrolls to that day;
/// swiping to another month swaps the list to that month.
class DailyAgenda extends StatefulWidget {
  const DailyAgenda({super.key});

  @override
  State<DailyAgenda> createState() => _DailyAgendaState();
}

class _DailyAgendaState extends State<DailyAgenda> {
  final Map<DateTime, GlobalKey> _sectionKeys = {};

  /// Month the list was last scrolled for, to tell a month swipe from a tap.
  late DateTime _shownMonth;

  @override
  void initState() {
    super.initState();
    _shownMonth = context.read<CalendarBloc>().state.visibleMonth;
  }

  GlobalKey _keyFor(DateTime day) => _sectionKeys.putIfAbsent(day, GlobalKey.new);

  /// Every day of [month]. Days without logs show "No event".
  List<DateTime> _daysFor(DateTime month) {
    final count = DateTime(month.year, month.month + 1, 0).day;
    return [
      for (var d = 1; d <= count; d++) DateTime(month.year, month.month, d),
    ];
  }

  void _onStateChanged(CalendarState state) {
    final monthChanged = state.visibleMonth != _shownMonth;
    _shownMonth = state.visibleMonth;

    if (!monthChanged) return _jumpTo(state.selectedDay, animate: true);

    // New month: start at today if it's in this month, otherwise the 1st.
    final today = MonthGrid.dateOnly(DateTime.now());
    final todayInMonth =
        today.year == state.visibleMonth.year && today.month == state.visibleMonth.month;
    _jumpTo(todayInMonth ? today : state.visibleMonth, animate: false);
  }

  void _jumpTo(DateTime day, {required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _sectionKeys[day]?.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalendarBloc, CalendarState>(
      listenWhen: (prev, curr) =>
          prev.selectedDay != curr.selectedDay ||
          prev.visibleMonth != curr.visibleMonth ||
          (prev.isLoading && !curr.isLoading),
      listener: (_, state) => _onStateChanged(state),
      builder: (_, state) {
        final today = MonthGrid.dateOnly(DateTime.now());

        return SingleChildScrollView(
          child: Column(
            children: [
              for (final day in _daysFor(state.visibleMonth))
                AgendaSection(
                  key: _keyFor(day),
                  day: day,
                  today: today,
                  logs: state.logsOn(day),
                ),
            ],
          ),
        );
      },
    );
  }
}

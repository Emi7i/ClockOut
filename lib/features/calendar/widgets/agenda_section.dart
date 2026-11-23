import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/month_grid.dart';
import '../../../domain/entities/log_entry.dart';
import 'log_event_row.dart';
import 'no_event_row.dart';

/// A day header strip followed by that day's log (or "No event").
class AgendaSection extends StatelessWidget {
  final DateTime day;
  final DateTime today;
  final LogEntry? log;

  /// Called with the log when its edit pen is tapped.
  final void Function(LogEntry log)? onEdit;

  const AgendaSection({
    super.key,
    required this.day,
    required this.today,
    required this.log,
    this.onEdit,
  });

  static const double headerHeight = 35;

  String get _title {
    final date = DateFormatter.weekdayMonthDay(day);
    final daysFromToday = day.difference(today).inDays;
    return switch (daysFromToday) {
      0 => 'Today · $date',
      1 => 'Tomorrow · $date',
      _ => date,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isToday = MonthGrid.isSameDay(day, today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: headerHeight,
          color: AppColors.agendaHeader,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.centerLeft,
          child: Text(
            _title,
            style: AppTextStyles.agendaHeader.copyWith(
              color: isToday ? accent : AppColors.calendarText,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        if (log case final log?)
          LogEventRow(
            log: log,
            onEdit: log.onlineWork || onEdit == null ? null : () => onEdit!(log),
          )
        else
          const NoEventRow(),
      ],
    );
  }
}

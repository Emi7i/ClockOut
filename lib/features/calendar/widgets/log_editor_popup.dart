import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/month_grid.dart';
import '../../../domain/entities/log_entry.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../bloc/calendar_bloc.dart';
import 'log_type_slider.dart';

/// The small window for adding a log and for editing one.
///
/// Normal and remote days pick a date (normal also picks enter/leave times).
/// Vacation replaces everything below the type with a From/To date range, so
/// several days can be labelled at once. When [editing] is set the window is
/// prefilled, says "Save", and shows a trash can in the top right.
class LogEditorPopup extends StatefulWidget {
  /// The log being edited, or `null` when adding.
  final LogEntry? editing;

  /// Called when the popup should go away (Cancel, Save/Add, Delete).
  final VoidCallback onClose;

  const LogEditorPopup({super.key, this.editing, required this.onClose});

  static const double width = 209;
  static const double height = 262;

  @override
  State<LogEditorPopup> createState() => _LogEditorPopupState();
}

class _LogEditorPopupState extends State<LogEditorPopup> {
  late LogType _type;
  late DateTime _day;
  late DateTime _from;
  late DateTime _to;
  TimeOfDay? _enter;
  TimeOfDay? _leave;

  bool get _isEditing => widget.editing != null;
  bool get _isVacation => _type == LogType.vacation;
  bool get _takesTimes => _type == LogType.normal;

  @override
  void initState() {
    super.initState();
    final log = widget.editing;
    _type = log?.type ?? LogType.normal;
    _day = log == null
        ? context.read<CalendarBloc>().state.selectedDay
        : MonthGrid.dateOnly(log.date);
    _from = _day;
    _to = _day;
    _enter = _timeOf(log?.clockedInTime);
    _leave = _timeOf(log?.clockedOutTime);
  }

  static TimeOfDay? _timeOf(DateTime? dt) =>
      dt == null ? null : TimeOfDay.fromDateTime(dt);

  bool get _is12Hour {
    final settings = context.read<SettingsBloc>().state;
    return settings is SettingsLoaded ? settings.is12HourFormat : true;
  }

  DateTime _at(DateTime day, TimeOfDay t) =>
      DateTime(day.year, day.month, day.day, t.hour, t.minute);

  void _setType(LogType type) {
    setState(() {
      if (type == LogType.vacation && !_isVacation) {
        _from = _day;
        _to = _day;
      } else if (type != LogType.vacation && _isVacation) {
        _day = _from;
      }
      _type = type;
    });
  }

  // ── Days ──────────────────────────────────────────────────────

  /// Every day the log(s) would cover.
  List<DateTime> get _days {
    if (!_isVacation) return [_day];
    return [
      for (var d = _from; !d.isAfter(_to); d = DateTime(d.year, d.month, d.day + 1)) d,
    ];
  }

  /// Whether another log (not the one being edited) already sits on [day].
  bool _isTaken(DateTime day) {
    final occupant = context.read<CalendarBloc>().state.logOn(day);
    final editing = widget.editing;
    return occupant != null && (editing == null || occupant.id != editing.id);
  }

  List<DateTime> get _freeDays => [
        for (final day in _days)
          if (!_isTaken(day)) day,
      ];

  int get _skippedDays => _days.length - _freeDays.length;

  // ── Validation ────────────────────────────────────────────────

  /// Why saving is blocked, shown under the fields; `null` when fine.
  String? get _problem {
    if (_freeDays.isEmpty) {
      return _isVacation
          ? 'Every one of these days already has a log'
          : 'A log already exists for this day';
    }
    if (_takesTimes &&
        _enter != null &&
        _leave != null &&
        !_at(_day, _leave!).isAfter(_at(_day, _enter!))) {
      return 'Leave must be after enter';
    }
    return null;
  }

  /// Non-blocking note (vacation ranges that overlap existing logs).
  String? get _note => _isVacation && _skippedDays > 0 && _problem == null
      ? '$_skippedDays already logged, skipped'
      : null;

  bool get _canSave =>
      _problem == null && (!_takesTimes || (_enter != null && _leave != null));

  // ── Pickers ───────────────────────────────────────────────────

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _day = MonthGrid.dateOnly(picked));
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _from, end: _to),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _from = MonthGrid.dateOnly(picked.start);
      _to = MonthGrid.dateOnly(picked.end);
    });
  }

  Future<void> _pickTime(TimeOfDay? initial, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: !_is12Hour),
        child: child!,
      ),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  // ── Actions ───────────────────────────────────────────────────

  LogEntry _entryFor(DateTime day, {int? id}) => LogEntry.manual(
        id: id,
        type: _type,
        day: day,
        clockedIn: _enter == null ? null : _at(day, _enter!),
        clockedOut: _leave == null ? null : _at(day, _leave!),
        shiftDuration: AppConstants.shiftDuration,
      );

  void _save() {
    final bloc = context.read<CalendarBloc>();
    final days = _freeDays;
    final editing = widget.editing;

    if (editing == null) {
      bloc.add(CalendarLogsAdded([for (final day in days) _entryFor(day)]));
    } else {
      // The edited log keeps its own day when the range still covers it.
      final ownDay = MonthGrid.dateOnly(editing.date);
      final keeps = days.contains(ownDay) ? ownDay : days.first;
      bloc.add(CalendarLogUpdated(
        _entryFor(keeps, id: editing.id),
        additional: [
          for (final day in days)
            if (day != keeps) _entryFor(day),
        ],
      ));
    }
    widget.onClose();
  }

  void _delete() {
    context.read<CalendarBloc>().add(CalendarLogDeleted(widget.editing!));
    widget.onClose();
  }

  String _timeText(TimeOfDay? t) =>
      t == null ? '' : DateFormatter.clockTime(_at(_day, t), is12Hour: _is12Hour);

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Rebuild when logs change so the "already has a log" checks stay right.
    context.watch<CalendarBloc>();
    final accent = Theme.of(context).colorScheme.primary;
    final hint = _problem ?? _note;

    return Material(
      color: AppColors.calendarBackground,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: LogEditorPopup.width,
        height: LogEditorPopup.height,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 16),
              child: Column(
                children: [
                  Text(
                    _isEditing ? 'Edit log' : 'Add log',
                    style: AppTextStyles.popupTitle,
                  ),
                  const SizedBox(height: 14),

                  // ── Type ──────────────────────────────────
                  const Text('Type:', style: AppTextStyles.popupLabel),
                  const SizedBox(height: 4),
                  LogTypeSlider(selected: _type, onChanged: _setType),
                  const SizedBox(height: 14),

                  // ── Everything below the type ─────────────
                  SizedBox(
                    height: 78,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: _isVacation
                          ? _rangeFields(accent)
                          : _dayAndTimeFields(accent),
                    ),
                  ),

                  // ── Hint ──────────────────────────────────
                  SizedBox(
                    height: 16,
                    child: hint == null
                        ? null
                        : Center(
                            child: Text(
                              hint,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.popupLabel.copyWith(
                                fontSize: 9,
                                color: _problem != null
                                    ? AppColors.negative
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                  ),
                  const Spacer(),

                  // ── Buttons ───────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Field(
                        width: 83,
                        height: 31,
                        color: AppColors.popupCancel,
                        onTap: widget.onClose,
                        child: const Center(
                          child: Text('Cancel', style: AppTextStyles.popupButton),
                        ),
                      ),
                      const SizedBox(width: 9),
                      _Field(
                        width: 83,
                        height: 31,
                        color: accent,
                        enabled: _canSave,
                        onTap: _save,
                        child: Center(
                          child: Text(
                            _isEditing ? 'Save' : 'Add',
                            style: AppTextStyles.popupButton,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Trash (editing only) ──────────────────────
            if (_isEditing)
              Positioned(
                top: 8,
                right: 8,
                child: Tooltip(
                  message: 'Delete log',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _delete,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(
                        'assets/icons/delete.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.negative,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Date row, then the enter/leave times (disabled for remote days).
  Widget _dayAndTimeFields(Color accent) {
    return Column(
      key: const ValueKey('day-and-times'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Field(
              width: 108,
              height: 24,
              onTap: _pickDay,
              child: Center(
                child: Text(
                  DateFormatter.weekdaySlashDate(_day),
                  style: AppTextStyles.popupLabel,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Field(
              width: 37,
              height: 24,
              color: accent,
              onTap: _pickDay,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/calendar_today.svg',
                  width: 14,
                  height: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LabeledField(
              label: 'Time enter:',
              text: _timeText(_enter),
              enabled: _takesTimes,
              onTap: () => _pickTime(_enter, (t) => _enter = t),
            ),
            const SizedBox(width: 9),
            _LabeledField(
              label: 'Time leave:',
              text: _timeText(_leave),
              enabled: _takesTimes,
              onTap: () => _pickTime(_leave, (t) => _leave = t),
            ),
          ],
        ),
      ],
    );
  }

  /// Vacation: a From / To date range in place of the date and times.
  Widget _rangeFields(Color accent) {
    return Row(
      key: const ValueKey('range'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LabeledField(
          label: 'From:',
          text: DateFormatter.slashDate(_from),
          onTap: _pickRange,
        ),
        const SizedBox(width: 9),
        _LabeledField(
          label: 'To:',
          text: DateFormatter.slashDate(_to),
          onTap: _pickRange,
        ),
      ],
    );
  }
}

/// A small centered label above a tappable field.
class _LabeledField extends StatelessWidget {
  final String label;
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  const _LabeledField({
    required this.label,
    required this.text,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.popupLabel),
        const SizedBox(height: 4),
        _Field(
          width: 81,
          height: 24,
          enabled: enabled,
          onTap: onTap,
          child: Center(child: Text(text, style: AppTextStyles.popupLabel)),
        ),
      ],
    );
  }
}

/// A rounded, tappable rectangle; dimmed and inert when [enabled] is false.
class _Field extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;

  const _Field({
    required this.width,
    required this.height,
    required this.child,
    required this.onTap,
    this.color = AppColors.popupField,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? onTap : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

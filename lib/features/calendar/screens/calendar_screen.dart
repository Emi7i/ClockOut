import 'package:flutter/material.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../widgets/add_button.dart';

/// ─────────────────────────────────────────────────────────────
///  CALENDAR SCREEN  (UI shell only — no data / logic wired yet)
///  Month grid with glowing status dots, a day-by-day status
///  list below, and a "+" speed-dial for adding entries.
/// ─────────────────────────────────────────────────────────────

enum DayStatus { onTime, online, vacation, late }

// Status colours (the accent colour stays user-swappable; these are fixed).
const Color _kOnTime = Color(0xFF5BD66B);
const Color _kOnline = Color(0xFF3D7BE8);
const Color _kVacation = Color(0xFFFF7FBF);
const Color _kLate = Color(0xFFE05555);

Color _statusColor(DayStatus s) => switch (s) {
      DayStatus.onTime => _kOnTime,
      DayStatus.online => _kOnline,
      DayStatus.vacation => _kVacation,
      DayStatus.late => _kLate,
    };

// Plain (non hand-drawn) text for this screen; font set in AppTextStyles.calendarFont.
const TextStyle _text = TextStyle(
  fontFamily: AppTextStyles.calendarFont,
  color: AppColors.textPrimary,
  fontSize: 16,
);

const Color _kPanel = Color(0xFF242628);

// ── Placeholder data (matches the wireframe: July 2026) ────────
final DateTime _kMonth = DateTime(2026, 7);
const int _kSelectedDay = 1;
const Map<int, DayStatus> _kMockStatuses = {
  3: DayStatus.onTime,
  6: DayStatus.online,
  8: DayStatus.online,
  9: DayStatus.online,
  10: DayStatus.late,
  14: DayStatus.online,
  15: DayStatus.online,
  16: DayStatus.online,
  17: DayStatus.online,
  21: DayStatus.onTime,
  24: DayStatus.vacation,
};

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class CalendarScreen extends StatefulWidget {
  final VoidCallback onBack;
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const CalendarScreen({
    super.key,
    required this.onBack,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menu = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_menu.isDismissed || _menu.status == AnimationStatus.reverse) {
      _menu.forward();
    } else {
      _menu.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_menu.value > 0) {
          _menu.reverse();
        } else {
          widget.onBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    const _CalendarBody(),

                    // ── Dim scrim while the menu is open ──────
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _menu,
                        builder: (context, _) => IgnorePointer(
                          ignoring: _menu.value == 0,
                          child: GestureDetector(
                            onTap: _toggleMenu,
                            child: ColoredBox(
                              color: Colors.black
                                  .withValues(alpha: 0.55 * _menu.value),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── "+" speed dial ────────────────────────
                    Positioned(
                      right: AppDimensions.screenPaddingH,
                      bottom: 12,
                      child: _AddMenu(controller: _menu, onToggle: _toggleMenu),
                    ),
                  ],
                ),
              ),
              AppNavBar(
                selectedIndex: widget.navIndex,
                onItemTapped: widget.onNavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Body: header + calendar + status list ────────────────────
class _CalendarBody extends StatelessWidget {
  const _CalendarBody();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // ── Calendar area ────────────────────────────────────
        Container(
          color: _kPanel,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.textPrimary, width: 1.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.calendar_today_outlined,
                        size: 20, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 28),
                  Text(
                    '${_monthNames[_kMonth.month - 1]} ${_kMonth.year}',
                    style: _text.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 17),
                  ),
                  Icon(Icons.keyboard_arrow_up_rounded,
                      color: accent, size: 22),
                  const Spacer(),
                  const Icon(Icons.more_vert, color: AppColors.textPrimary),
                ],
              ),
              const SizedBox(height: 18),

              // Weekday labels
              Row(
                children: [
                  for (final d in _weekdays)
                    Expanded(
                      child: Center(
                        child: Text(d,
                            style: _text.copyWith(
                                fontSize: 15, color: AppColors.textSecondary)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              const _MonthGrid(),

              // Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Status list ──────────────────────────────────────
        const Expanded(child: _StatusList()),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final daysInMonth = DateUtils.getDaysInMonth(_kMonth.year, _kMonth.month);
    final leading = _kMonth.weekday - 1; // Monday-first
    final rows = ((leading + daysInMonth) / 7).ceil();

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          SizedBox(
            height: 54,
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                      child:
                          _cell(r * 7 + c - leading + 1, daysInMonth, accent)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(int day, int daysInMonth, Color accent) {
    if (day < 1 || day > daysInMonth) return const SizedBox.shrink();

    final selected = day == _kSelectedDay;
    final status = _kMockStatuses[day];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(color: accent, shape: BoxShape.circle)
              : null,
          child: Text(
            '$day',
            style: _text.copyWith(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? AppColors.background : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 7,
          child: status == null ? null : _GlowDot(color: _statusColor(status)),
        ),
      ],
    );
  }
}

class _GlowDot extends StatelessWidget {
  final Color color;
  const _GlowDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Day-by-day status list ───────────────────────────────────
class _StatusList extends StatelessWidget {
  const _StatusList();

  @override
  Widget build(BuildContext context) {
    final days = _kMockStatuses.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96), // clear of the + button
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final date = DateTime(_kMonth.year, _kMonth.month, day);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: _kPanel,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                '${_weekdayNames[date.weekday - 1]}, '
                '${day.toString().padLeft(2, '0')} ${_monthNames[date.month - 1]}',
                style: _text.copyWith(color: AppColors.textSecondary),
              ),
            ),
            _StatusCard(status: _kMockStatuses[day]!),
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final DayStatus status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = switch (status) {
      DayStatus.onTime => 'On time',
      DayStatus.online => 'Online work',
      DayStatus.vacation => 'Vacation day',
      DayStatus.late => 'Late',
    };

    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(14, 16, 18, 16),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: _text.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (status == DayStatus.late)
              Text('-30 minutes',
                  style:
                      _text.copyWith(color: color, fontWeight: FontWeight.w600))
            else
              Icon(
                status == DayStatus.vacation
                    ? Icons.beach_access_rounded
                    : Icons.check_rounded,
                color: color,
                size: 26,
              ),
          ],
        ),
      ),
    );
  }
}

// ── "+" speed dial ───────────────────────────────────────────
class _AddMenu extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onToggle;

  const _AddMenu({required this.controller, required this.onToggle});

  static const _options = [
    'Manual checkin',
    'Add online work',
    'Add vacation',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _options.length; i++) _bubble(context, i),
            AddButton(
              turns: 0.125 *
                  Curves.easeOutBack
                      .transform(controller.value.clamp(0.0, 1.0)),
              onTap: onToggle,
            ),
          ],
        );
      },
    );
  }

  Widget _bubble(BuildContext context, int index) {
    final accent = Theme.of(context).colorScheme.primary;
    final label = _options[index];

    // The bubble nearest the button (last index) animates first.
    final order = _options.length - 1 - index;
    final start = order * 0.15;
    final t = Curves.easeOutCubic.transform(
      Interval(start, start + 0.55).transform(controller.value),
    );

    if (t == 0) return const SizedBox.shrink();

    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 24),
        child: Transform.scale(
          scale: 0.7 + 0.3 * t,
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: 230,
              child: Material(
                color: Color.alphaBlend(
                    accent.withValues(alpha: 0.14), const Color(0xFF1C1D1F)),
                elevation: 4,
                shadowColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: accent, width: 1.5),
                ),
                child: InkWell(
                  onTap: () => controller.reverse(), // TODO: wire up actions
                  customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, size: 22, color: accent),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: _text.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

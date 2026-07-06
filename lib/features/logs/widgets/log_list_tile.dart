import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/log_entry.dart';

/// ─────────────────────────────────────────────────────────────
///  LOG LIST TILE
///  One row in the logs list: date + time on the left, status on
///  the right. Text colour is driven by [LogStatus].
///
///  When [onTap] is provided (edit mode), the row is tappable and
///  shows an edit affordance.
/// ─────────────────────────────────────────────────────────────
class LogListTile extends StatelessWidget {
  final LogEntry     entry;
  final VoidCallback? onTap;

  const LogListTile({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = switch (entry.status) {
      LogStatus.onTime => AppTextStyles.logNeutral,
      LogStatus.early  => AppTextStyles.logPositive,
      LogStatus.late   => AppTextStyles.logNegative,
    };

    final dateTimeLabel = entry.clockedOutTime != null
        ? '${DateFormatter.logDate(entry.date)}  ${DateFormatter.clockTime(entry.clockedOutTime!)}'
        : DateFormatter.logDate(entry.date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical:   AppDimensions.spaceXs,
          horizontal: AppDimensions.spaceSm,
        ),
        child: Row(
          children: [
            // ── Date + time ─────────────────────────────────
            Text(dateTimeLabel, style: style),

            // ── Guaranteed minimum gap ───────────────────────
            const SizedBox(width: AppDimensions.spaceLg),

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ── Offset label ─────────────────────────────
                  Text(entry.offsetLabel, style: style),

                  if (onTap != null) ...[
                    const SizedBox(width: AppDimensions.spaceXs),
                    Icon(Icons.edit_outlined, size: 16, color: style.color),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

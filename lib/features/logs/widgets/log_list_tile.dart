import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/log_entry.dart';

/// ─────────────────────────────────────────────────────────────
///  LOG LIST TILE
///  One row in the logs list: date on the left, offset on the right.
///  Text colour is driven by [LogStatus] — swap in app_colors.dart.
/// ─────────────────────────────────────────────────────────────
class LogListTile extends StatelessWidget {
  final LogEntry entry;

  const LogListTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final style = switch (entry.status) {
      LogStatus.onTime => AppTextStyles.logNeutral,
      LogStatus.early  => AppTextStyles.logPositive,
      LogStatus.late   => AppTextStyles.logNegative,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Date ────────────────────────────────────────
          Text(DateFormatter.logDate(entry.date), style: style),

          // ── Offset label ─────────────────────────────────
          Text(entry.offsetLabel, style: style),
        ],
      ),
    );
  }
}

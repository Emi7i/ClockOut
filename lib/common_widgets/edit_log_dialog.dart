import 'package:material_ui/material_ui.dart';
import '../core/constants/constants.dart';
import '../core/utils/date_formatter.dart';

/// ─────────────────────────────────────────────────────────────
///  EDIT LOG DIALOG
///  Lets the user pick new start/end times for a log, or delete it.
///  Shared by the Logs and Calendar screens; the caller decides what
///  saving / deleting actually does.
/// ─────────────────────────────────────────────────────────────
Future<void> showEditLogDialog(
  BuildContext context, {
  required DateTime start,
  required DateTime end,
  required bool is12Hour,
  required void Function(DateTime start, DateTime end) onSave,
  required VoidCallback onDelete,
}) {
  MediaQuery timePickerTheme(BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: !is12Hour),
        child: child!,
      );

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> pickStart() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(start),
            builder: timePickerTheme,
          );
          if (picked == null) return;
          setState(() {
            start = DateTime(start.year, start.month, start.day, picked.hour, picked.minute);
            // Keep the end time on/after the new start time.
            if (!end.isAfter(start)) {
              end = start.add(const Duration(hours: 1));
            }
          });
        }

        Future<void> pickEnd() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(end),
            builder: timePickerTheme,
          );
          if (picked == null) return;
          setState(() {
            var newEnd = DateTime(start.year, start.month, start.day, picked.hour, picked.minute);
            // Assume an overnight shift if the end time-of-day is before start.
            if (!newEnd.isAfter(start)) {
              newEnd = newEnd.add(const Duration(days: 1));
            }
            end = newEnd;
          });
        }

        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Edit log', style: AppTextStyles.bodyLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EditTimeRow(label: 'Start', time: start, is12Hour: is12Hour, onTap: pickStart),
              const SizedBox(height: AppDimensions.spaceSm),
              _EditTimeRow(label: 'End', time: end, is12Hour: is12Hour, onTap: pickEnd),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                onDelete();
                Navigator.of(dialogContext).pop();
              },
              child: Text('Delete', style: AppTextStyles.destructiveButton),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel', style: AppTextStyles.bodySmall),
                ),
                TextButton(
                  onPressed: () {
                    onSave(start, end);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Save',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _EditTimeRow extends StatelessWidget {
  final String       label;
  final DateTime     time;
  final bool         is12Hour;
  final VoidCallback onTap;

  const _EditTimeRow({
    required this.label,
    required this.time,
    required this.is12Hour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            Row(
              children: [
                Text(
                  DateFormatter.clockTime(time, is12Hour: is12Hour),
                  style: AppTextStyles.bodyMedium.copyWith(color: accentColor),
                ),
                const SizedBox(width: AppDimensions.spaceXs),
                Icon(Icons.access_time_rounded, size: 18, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

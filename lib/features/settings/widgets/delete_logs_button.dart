import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

/// ─────────────────────────────────────────────────────────────
///  DELETE LOGS BUTTON
///  Dashed red border button at the bottom of Settings.
///  Shows a confirmation dialog before firing [onConfirmed].
///  Swap [label] or [confirmMessage] to change copy.
/// ─────────────────────────────────────────────────────────────
class DeleteLogsButton extends StatelessWidget {
  final VoidCallback onConfirmed;

  /// ← Change button copy here
  final String label          = 'Delete all Logs';
  final String confirmMessage = 'This will permanently delete all clock logs. Continue?';

  const DeleteLogsButton({super.key, required this.onConfirmed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirm(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        AppColors.negative.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: AppColors.negative,
            width: 1.5,
            // For a truly dashed border swap this container for
            // a CustomPaint with a dashed border painter.
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style:     AppTextStyles.destructiveButton,
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title:   Text('Delete all logs?', style: AppTextStyles.bodyLarge),
        content: Text(confirmMessage,      style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppTextStyles.destructiveButton,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) onConfirmed();
  }
}

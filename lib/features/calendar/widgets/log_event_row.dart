import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/log_entry.dart';
import '../cat_assets.dart';

/// A single log in the agenda: cat avatar, bonus/late summary, clock times.
class LogEventRow extends StatelessWidget {
  final LogEntry log;
  final VoidCallback? onEdit;

  const LogEventRow({super.key, required this.log, this.onEdit});

  static const double _avatarSize = 57;

  @override
  Widget build(BuildContext context) {
    final clockedIn = log.clockedInTime;
    final clockedOut = log.clockedOutTime;

    return Container(
      height: 94,
      color: AppColors.agendaRow,
      padding: const EdgeInsets.only(left: 15, right: 6),
      child: Row(
        children: [
          SvgPicture.asset(
            CatAssets.forLog(log),
            width: _avatarSize,
            height: _avatarSize,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Title(log: log),
                const SizedBox(height: 6),
                if (log.usedBank)
                  const Text(
                    'Used time from bank',
                    style: AppTextStyles.agendaEventDetail,
                  ),
                if (clockedIn != null)
                  Text(
                    'Clocked in at ${DateFormatter.compactTime(clockedIn)}',
                    style: AppTextStyles.agendaEventDetail,
                  ),
                if (clockedOut != null)
                  Text(
                    'Clocked out at ${DateFormatter.compactTime(clockedOut)}',
                    style: AppTextStyles.agendaEventDetail,
                  ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: SvgPicture.asset(
                'assets/icons/edit.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final LogEntry log;
  const _Title({required this.log});

  @override
  Widget build(BuildContext context) {
    final amount = DateFormatter.bonusDuration(log.bonusTime);

    switch (log.type) {
      case LogType.vacation:
        return const Text('Vacation', style: AppTextStyles.agendaEventTitle);
      case LogType.remote:
        return const Text('Remote work', style: AppTextStyles.agendaEventTitle);
      case LogType.normal:
        break;
    }

    return switch (log.status) {
      LogStatus.onTime =>
        const Text('Just in time', style: AppTextStyles.agendaEventTitle),
      LogStatus.early => Text.rich(TextSpan(
          style: AppTextStyles.agendaEventTitle,
          children: [
            const TextSpan(text: 'Bonus '),
            TextSpan(
              text: amount,
              style: const TextStyle(color: AppColors.bonus),
            ),
          ],
        )),
      LogStatus.late => Text.rich(TextSpan(
          style: AppTextStyles.agendaEventTitle,
          children: [
            const TextSpan(text: 'Left early '),
            TextSpan(
              text: amount,
              style: const TextStyle(color: AppColors.negative),
            ),
          ],
        )),
    };
  }
}

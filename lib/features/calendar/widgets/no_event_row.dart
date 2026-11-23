import 'package:material_ui/material_ui.dart';
import '../../../core/constants/constants.dart';

class NoEventRow extends StatelessWidget {
  const NoEventRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      color: AppColors.agendaRow,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      alignment: Alignment.centerLeft,
      child: const Text('No event', style: AppTextStyles.agendaEmpty),
    );
  }
}

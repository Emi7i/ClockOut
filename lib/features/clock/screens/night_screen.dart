import 'package:material_ui/material_ui.dart';

import '../../../core/constants/constants.dart';
import '../widgets/scene/scene_backdrop.dart';

/// ─────────────────────────────────────────────────────────────
///  NIGHT SCREEN
///  The end state of the Day→Night timeline (progress = 1).
///  A separate screen from [HomeScreen]; wired in with the swipe
///  gesture (phase 3).
/// ─────────────────────────────────────────────────────────────
class NightScreen extends StatelessWidget {
  const NightScreen({super.key});

  static const _night = AlwaysStoppedAnimation<double>(1);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.skyTop,
      body: SceneBackdrop(progress: _night),
    );
  }
}

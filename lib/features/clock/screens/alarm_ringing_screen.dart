import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../common_widgets/common_widgets.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../bloc/clock_bloc.dart';

/// ─────────────────────────────────────────────────────────────
///  ALARM RINGING SCREEN
///  Full-screen banner that takes over the app — like a system clock
///  app's ringing screen — whenever [ClockActive.isRinging] is true.
///  Pushed/popped by [AppShell] in response to [ClockBloc] state.
/// ─────────────────────────────────────────────────────────────
class AlarmRingingScreen extends StatelessWidget {
  const AlarmRingingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.read<ClockBloc>().add(const AlarmStopRequested()),
          child: SafeArea(
            child: BlocBuilder<ClockBloc, ClockState>(
              builder: (context, state) {
                final now = state is ClockActive ? state.currentTime : DateTime.now();
                final settingsState = context.watch<SettingsBloc>().state;
                final is12Hour = settingsState is SettingsLoaded ? settingsState.is12HourFormat : true;

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PulsingIcon(),

                      const SizedBox(height: AppDimensions.spaceLg),

                      Text(
                        DateFormatter.clockTime(now, is12Hour: is12Hour),
                        style: AppTextStyles.timeDisplay,
                      ),

                      const SizedBox(height: AppDimensions.spaceSm),

                      const Text('Shift over!', style: AppTextStyles.screenTitle),

                      const SizedBox(height: AppDimensions.spaceXs),

                      const Text(
                        'Time to clock out.',
                        style: AppTextStyles.bodyMedium,
                      ),

                      const SizedBox(height: AppDimensions.spaceXl),

                      OvalActionButton(
                        label: 'Stop the Alarm',
                        onPressed: () =>
                            context.read<ClockBloc>().add(const AlarmStopRequested()),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return ScaleTransition(
      scale: Tween(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.alarm_rounded,
          color: accentColor,
          size: 52,
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../widgets/scene/scene_backdrop.dart';
import '../widgets/scene/ufo_and_card.dart';

/// ─────────────────────────────────────────────────────────────
///  HOME SCENE
///  The Figma Day↔Night scene. ONE value, [_progress] (0 = Day,
///  1 = Night), drives every layer through `SceneTimeline`.
///  Playing forward, in reverse and (phase 3) following the
///  finger all move this same value.
/// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onCalendarTap;

  const HomeScreen({
    super.key,
    required this.onSettingsTap,
    required this.onCalendarTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// 0 = Day (timeline at t=0), 1 = Night. Linear: the Figma easing lives in
  /// the per-layer tracks, not here.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: AppConstants.sceneDuration,
  );

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  /// Debug: play to the other state.
  void _toggle() {
    if (_progress.isAnimating) {
      _progress.isForwardOrCompleted ? _progress.forward() : _progress.reverse();
      return;
    }
    _progress.value >= 0.5 ? _progress.reverse() : _progress.forward();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final is12Hour = settings is SettingsLoaded ? settings.is12HourFormat : true;

    return Scaffold(
      backgroundColor: AppColors.skyTop,
      body: Stack(
        children: [
          Positioned.fill(child: SceneBackdrop(progress: _progress)),
          Positioned.fill(child: UfoAndCard(progress: _progress)),
          SafeArea(
            child: Column(
              children: [
                LiveClockTopBar(
                  is12Hour: is12Hour,
                  onSettingsTap: widget.onSettingsTap,
                  onCalendarTap: widget.onCalendarTap,
                ),
                const Spacer(),
                if (kDebugMode) _DebugScrubber(progress: _progress, onPlay: _toggle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Temporary phase-2 controls: a play/reverse button and a scrubber bound to
/// the same progress value.
class _DebugScrubber extends StatelessWidget {
  final AnimationController progress;
  final VoidCallback onPlay;
  const _DebugScrubber({required this.progress, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(
          children: [
            TextButton(
              onPressed: onPlay,
              child: Text(progress.value >= 0.5 ? '◀ Day' : 'Night ▶'),
            ),
            Expanded(
              child: Slider(
                value: progress.value,
                onChangeStart: (_) => progress.stop(),
                onChanged: (v) => progress.value = v,
              ),
            ),
            SizedBox(
              width: 38,
              child: Text(progress.value.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// [AppTopBar] with a clock that keeps ticking (the idle bloc state has no
/// ticker of its own).
class LiveClockTopBar extends StatefulWidget {
  final bool is12Hour;
  final VoidCallback onSettingsTap;
  final VoidCallback? onCalendarTap;

  const LiveClockTopBar({
    super.key,
    required this.is12Hour,
    required this.onSettingsTap,
    this.onCalendarTap,
  });

  @override
  State<LiveClockTopBar> createState() => _LiveClockTopBarState();
}

class _LiveClockTopBarState extends State<LiveClockTopBar> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      timeLabel: DateFormatter.clockTime(_now, is12Hour: widget.is12Hour),
      onSettingsTap: widget.onSettingsTap,
      onCalendarTap: widget.onCalendarTap,
    );
  }
}

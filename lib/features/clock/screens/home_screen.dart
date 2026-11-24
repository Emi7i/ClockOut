import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../common_widgets/common_widgets.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../bloc/clock_bloc.dart';
import '../widgets/scene/scene_backdrop.dart';
import '../widgets/scene/scene_swipe.dart';
import '../widgets/scene/shift_clock.dart';
import '../widgets/scene/shift_layer.dart';

/// ─────────────────────────────────────────────────────────────
///  HOME SCENE
///  The Figma Day↔Night scene, for BOTH clock states (idle and clocked in).
///  Three independent values drive it:
///   * [_progress]  0 = Day, 1 = Night (every backdrop layer, via
///                  SceneTimeline; the swipe and the debug controls move it)
///   * [_intro]     the 3 s "Start Shift" UFO timeline, played once forward
///   * [_ring]      endless, decorative turning of the dashed ring
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  /// 0 = Day (timeline at t=0), 1 = Night. Linear: the Figma easing lives in
  /// the per-layer tracks, not here.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: AppConstants.sceneDuration,
  );

  /// 0 = idle (card showing), 1 = UFO parked on the ring with beam and ring.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: AppConstants.shiftIntroDuration,
  );

  /// One full turn per 1 / ringTurnsPerSecond seconds; wraps seamlessly.
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration:
        Duration(microseconds: (1e6 / AppConstants.ringTurnsPerSecond).round()),
  )..repeat();

  /// Debug only: fast-forward the orbit (see AppConstants.debugTimeScale).
  final ValueNotifier<bool> _fast = ValueNotifier<bool>(false);

  final ValueNotifier<String> _debugLog =
      ValueNotifier<String>('swipe up / down');

  @override
  void initState() {
    super.initState();
    // Coming back with a shift already running (app restart, tab switch):
    // no intro, go straight to the "shift running" state.
    if (context.read<ClockBloc>().state is ClockActive) _intro.value = 1;
  }

  @override
  void dispose() {
    _fast.dispose();
    _debugLog.dispose();
    _ring.dispose();
    _intro.dispose();
    _progress.dispose();
    super.dispose();
  }

  /// Where the UFO is on its orbit right now, from the persisted clock-in
  /// time (null when no shift is running). Called on every frame.
  double? _orbitFraction() {
    final state = context.read<ClockBloc>().state;
    if (state is! ClockActive) return null;
    final fast = kDebugMode && _fast.value;
    return shiftOrbitFraction(
      clockedInAt: state.clockedInAt,
      now: DateTime.now(),
      timeScale: fast ? AppConstants.debugTimeScale : 1,
      startOffset: fast ? AppConstants.shiftIntroDuration : Duration.zero,
    );
  }

  void _startShift() {
    if (_intro.value != 0 || _intro.isAnimating) return;
    _intro.forward();
    context.read<ClockBloc>().add(const ClockInRequested());
  }

  /// Debug: play to the other state.
  void _toggle() {
    if (_progress.isAnimating) {
      _progress.isForwardOrCompleted
          ? _progress.forward()
          : _progress.reverse();
      return;
    }
    _progress.value >= 0.5 ? _progress.reverse() : _progress.forward();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final is12Hour =
        settings is SettingsLoaded ? settings.is12HourFormat : true;

    return BlocListener<ClockBloc, ClockState>(
      listener: (context, state) {
        // Shift ended (phase 6 turns this into the full clock-out sequence).
        if (state is ClockIdle && _intro.value != 0) _intro.reverse();
        // Shift started from somewhere else than the card.
        if (state is ClockActive && _intro.value == 0 && !_intro.isAnimating) {
          _intro.forward();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.skyTop,
        body: SceneSwipe(
          controller: _progress,
          debugLog: _debugLog,
          child: Stack(
            children: [
              Positioned.fill(child: SceneBackdrop(progress: _progress)),
              Positioned.fill(
                child: ShiftLayer(
                  scene: _progress,
                  intro: _intro,
                  ringTurns: _ring,
                  orbitFraction: _orbitFraction,
                  onStartShift: _startShift,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    LiveClockTopBar(
                      is12Hour: is12Hour,
                      onSettingsTap: widget.onSettingsTap,
                      onCalendarTap: widget.onCalendarTap,
                    ),
                    const Spacer(),
                    if (kDebugMode)
                      _DebugScrubber(
                          progress: _progress,
                          onPlay: _toggle,
                          log: _debugLog,
                          fast: _fast),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Temporary phase-2 controls: a play/reverse button and a scrubber bound to
/// the same progress value.
class _DebugScrubber extends StatelessWidget {
  final AnimationController progress;
  final VoidCallback onPlay;
  final ValueListenable<String> log;
  final ValueNotifier<bool> fast;
  const _DebugScrubber({
    required this.progress,
    required this.onPlay,
    required this.log,
    required this.fast,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<String>(
              valueListenable: log,
              builder: (_, v, __) =>
                  Text(v, style: const TextStyle(fontSize: 12)),
            ),
            Row(
              children: [
                if (context.watch<ClockBloc>().state is ClockActive) ...[
                  ValueListenableBuilder<bool>(
                    valueListenable: fast,
                    builder: (_, on, __) => TextButton(
                      onPressed: () => fast.value = !on,
                      child: Text(on ? '×${AppConstants.debugTimeScale.round()}' : '×1'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context
                        .read<ClockBloc>()
                        .add(const ClockOutRequested()),
                    child: const Text('Clock out (debug)'),
                  ),
                ],
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

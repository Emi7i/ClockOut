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
import '../widgets/scene/scene_timeline.dart';
import '../widgets/scene/shift_clock.dart';
import '../widgets/scene/shift_layer.dart';
import '../widgets/scene/ufo_pose.dart';

/// ─────────────────────────────────────────────────────────────
///  HOME SCENE
///  The Figma Day↔Night scene, for BOTH clock states (idle and clocked in).
///  Independent values drive it:
///   * [_progress]  0 = Day, 1 = Night (every backdrop layer, via
///                  SceneTimeline; the swipe moves it)
///   * [_intro]     the 3 s "Start Shift" UFO timeline: forward when a shift
///                  starts, in reverse at the end of the clock-out sequence
///   * [_loop]      the clock-out lap: the UFO circles out of sight and comes
///                  back in over the left edge
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

  /// 0..1 along the clock-out lap (its duration is set per lap).
  late final AnimationController _loop = AnimationController(vsync: this);

  /// One full turn per 1 / ringTurnsPerSecond seconds; wraps seamlessly.
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration:
        Duration(microseconds: (1e6 / AppConstants.ringTurnsPerSecond).round()),
  )..repeat();

  /// Ring angle where the current clock-out lap started (null = no lap).
  double? _loopFromAngle;

  /// The last orbit position shown, so a clock-out can continue from it.
  double _lastOrbitFraction = 0;

  /// Debug only: fast-forward the orbit (see AppConstants.debugTimeScale).
  final ValueNotifier<bool> _fast = ValueNotifier<bool>(false);

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
    _ring.dispose();
    _loop.dispose();
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
    return _lastOrbitFraction = shiftOrbitFraction(
      clockedInAt: state.clockedInAt,
      now: DateTime.now(),
      timeScale: fast ? AppConstants.debugTimeScale : 1,
      startOffset: fast ? AppConstants.shiftIntroDuration : Duration.zero,
    );
  }

  /// The UFO's pose for this frame, or null to follow the intro timeline.
  UfoPose? _ufoPose() {
    final from = _loopFromAngle;
    if (from != null) return UfoOrbit.loopPose(from, _loop.value);
    if (_intro.value < 1) return null; // intro (forward or in reverse)
    final f = _orbitFraction();
    return f == null ? null : UfoOrbit.poseAt(f);
  }

  void _startShift() {
    if (_intro.value != 0 || _intro.isAnimating || _loopFromAngle != null) {
      return;
    }
    _intro.forward();
    context.read<ClockBloc>().add(const ClockInRequested());
  }

  /// Clock-out: the UFO loops around the Earth out of sight, re-enters from
  /// the left edge at the intro's end point, then the intro plays in reverse
  /// (UFO back up, beam and ring fade, card returns).
  Future<void> _playClockOut() async {
    if (_loopFromAngle != null) return; // already running
    // Ended while the intro was still playing: just run it back.
    if (_intro.value < 1) {
      _intro.reverse();
      return;
    }
    final from = UfoOrbit.angleAt(_lastOrbitFraction);
    // Same speed on every lap: shorter laps take proportionally less time.
    final share = UfoOrbit.loopSweep(from) / UfoOrbit.fullLoopSweep;
    _loop.duration = AppConstants.clockOutLoopDuration * share;
    setState(() => _loopFromAngle = from);
    await _loop.forward(from: 0);
    if (!mounted) return;
    setState(() => _loopFromAngle = null);
    // The loop ends exactly on the intro's end pose, so hand over to it. Start
    // the reverse where the timeline has settled (the last part of the
    // timeline is a hold), so the UFO moves on at once.
    await _intro.reverse(from: ShiftTimeline.settledAt);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    final is12Hour =
        settings is SettingsLoaded ? settings.is12HourFormat : true;

    return BlocListener<ClockBloc, ClockState>(
      listener: (context, state) {
        // Shift ended: play the clock-out sequence.
        if (state is ClockIdle && _intro.value != 0) _playClockOut();
        // Shift started from somewhere else than the card.
        if (state is ClockActive && _intro.value == 0 && !_intro.isAnimating) {
          _intro.forward();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.skyTop,
        body: SceneSwipe(
          controller: _progress,
          child: Stack(
            children: [
              Positioned.fill(child: SceneBackdrop(progress: _progress)),
              Positioned.fill(
                child: ShiftLayer(
                  scene: _progress,
                  intro: _intro,
                  ringTurns: _ring,
                  ufoPose: _ufoPose,
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
                    if (kDebugMode) _DebugControls(fast: _fast),
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

/// Temporary, debug builds only: the End Shift button does not exist yet, and
/// the time scale lets an 8 h shift be watched in about 30 s.
class _DebugControls extends StatelessWidget {
  final ValueNotifier<bool> fast;
  const _DebugControls({required this.fast});

  @override
  Widget build(BuildContext context) {
    if (context.watch<ClockBloc>().state is! ClockActive) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: fast,
            builder: (_, on, __) => TextButton(
              onPressed: () => fast.value = !on,
              child:
                  Text(on ? '×${AppConstants.debugTimeScale.round()}' : '×1'),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.read<ClockBloc>().add(const ClockOutRequested()),
            child: const Text('Clock out (debug)'),
          ),
        ],
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

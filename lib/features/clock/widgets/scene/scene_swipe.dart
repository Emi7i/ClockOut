import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/constants.dart';

/// Where a released swipe should settle.
enum SceneTarget { day, night }

/// The release rule, as a pure function so it can be unit-tested.
///
/// [startedAtNight] is the resting state the drag began from. [movingTowardNight]
/// is the direction of the LAST movement before release (null = none seen).
///
/// * Day start: progress >= [commitPoint] -> Night. Before it: Night if the
///   last movement was toward Night (up), Day if it was back toward Day (down).
/// * Night start: the mirror image, using 1 - [commitPoint].
SceneTarget decideSceneTarget({
  required double progress,
  required bool startedAtNight,
  required bool? movingTowardNight,
  double commitPoint = AppConstants.sceneCommitPoint,
}) {
  if (!startedAtNight) {
    if (progress >= commitPoint) return SceneTarget.night;
  } else {
    if (progress <= 1 - commitPoint) return SceneTarget.day;
  }
  if (movingTowardNight == null) {
    // No usable movement: settle back to where the drag started.
    return startedAtNight ? SceneTarget.night : SceneTarget.day;
  }
  return movingTowardNight ? SceneTarget.night : SceneTarget.day;
}

/// Vertical swipe that drives the scene's ONE progress value.
///
/// While the finger is down, progress follows it (up = toward Night) and never
/// auto-completes. On release it animates the same [controller] to 0 or 1
/// according to [decideSceneTarget]. Taps and tiny movements are left to the
/// child: Flutter only starts a drag after the touch slop.
class SceneSwipe extends StatefulWidget {
  final AnimationController controller;
  final Widget child;

  /// Debug only: receives a one-line description of the last release.
  final ValueNotifier<String>? debugLog;

  const SceneSwipe({
    super.key,
    required this.controller,
    required this.child,
    this.debugLog,
  });

  @override
  State<SceneSwipe> createState() => _SceneSwipeState();
}

class _SceneSwipeState extends State<SceneSwipe> {
  bool _startedAtNight = false;
  double _startValue = 0;
  double _totalDy = 0;
  bool? _movingTowardNight;

  AnimationController get _c => widget.controller;

  void _onStart(DragStartDetails d) {
    _c.stop(); // grab the scene wherever it is
    _startValue = _c.value;
    _startedAtNight = _startValue >= 0.5;
    _totalDy = 0;
    _movingTowardNight = null;
  }

  void _onUpdate(DragUpdateDetails d, double height) {
    _totalDy += d.delta.dy;
    // Ignore sub-pixel jitter when judging the last movement's direction.
    if (d.delta.dy.abs() >= AppConstants.sceneMinDirectionDelta) {
      _movingTowardNight = d.delta.dy < 0;
    }
    final travel = height * AppConstants.sceneTravelFraction;
    _c.value = (_startValue - _totalDy / travel).clamp(0.0, 1.0);
  }

  void _onEnd(DragEndDetails d) => _settle();

  void _onCancel() => _settle();

  void _settle() {
    final target = decideSceneTarget(
      progress: _c.value,
      startedAtNight: _startedAtNight,
      movingTowardNight: _movingTowardNight,
    );
    final to = target == SceneTarget.night ? 1.0 : 0.0;
    final remaining = (to - _c.value).abs();
    widget.debugLog?.value = 'released ${_c.value.toStringAsFixed(2)} '
        '${_movingTowardNight == null ? '·' : _movingTowardNight! ? '↑' : '↓'}'
        ' → ${target.name}';
    if (remaining == 0) return;
    // Same value, same timeline: just run it to the end at timeline speed.
    _c.animateTo(
      to,
      duration: AppConstants.sceneDuration * remaining,
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: _onStart,
        onVerticalDragUpdate: (d) => _onUpdate(d, constraints.maxHeight),
        onVerticalDragEnd: _onEnd,
        onVerticalDragCancel: _onCancel,
        child: widget.child,
      ),
    );
  }
}

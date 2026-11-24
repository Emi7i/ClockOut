import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/constants.dart';

/// Where a swipe sends the scene.
enum SceneTarget { day, night }

/// Direction rule, as a pure function so it can be unit-tested.
///
/// Only the DIRECTION of the swipe matters, never its speed or length: up
/// goes to Night, down goes to Day. Returns null when the movement is too
/// small to count (a tap or a wobble).
SceneTarget? sceneTargetForSwipe(
  double totalDy, {
  double minDistance = AppConstants.sceneSwipeMinDistance,
}) {
  if (totalDy.abs() < minDistance) return null;
  return totalDy < 0 ? SceneTarget.night : SceneTarget.day;
}

/// Vertical swipe that triggers the Day↔Night animation.
///
/// The scene does NOT follow the finger. Once the swipe has moved far enough
/// to be deliberate, the shared [controller] runs to 0 (Day) or 1 (Night) at
/// the fixed timeline speed ([AppConstants.sceneDuration] for a full run), no
/// matter how fast or how far the finger went. A swipe the other way while it
/// is running turns it around from where it is, at the same speed.
class SceneSwipe extends StatefulWidget {
  final AnimationController controller;
  final Widget child;

  const SceneSwipe({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<SceneSwipe> createState() => _SceneSwipeState();
}

class _SceneSwipeState extends State<SceneSwipe> {
  double _totalDy = 0;
  bool _fired = false;

  AnimationController get _c => widget.controller;

  void _onStart(DragStartDetails d) {
    _totalDy = 0;
    _fired = false;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_fired) return; // one trigger per gesture
    _totalDy += d.delta.dy;
    final target = sceneTargetForSwipe(_totalDy);
    if (target == null) return;
    _fired = true;
    _play(target);
  }

  void _play(SceneTarget target) {
    final to = target == SceneTarget.night ? 1.0 : 0.0;
    final remaining = (to - _c.value).abs();
    if (remaining == 0) return;
    // Constant speed: a full run takes sceneDuration, a partial one less.
    _c.animateTo(
      to,
      duration: AppConstants.sceneDuration * remaining,
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: _onStart,
      onVerticalDragUpdate: _onUpdate,
      child: widget.child,
    );
  }
}

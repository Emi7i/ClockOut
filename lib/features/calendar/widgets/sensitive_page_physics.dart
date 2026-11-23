import 'package:material_ui/material_ui.dart';

/// Page snapping that turns the page after only a short drag (or any flick),
/// instead of requiring the page to be dragged past halfway.
///
/// Use with `PageView(pageSnapping: false)` — the default snapping would
/// otherwise wrap this physics and take over.
class SensitivePagePhysics extends ScrollPhysics {
  /// The page the current drag started on.
  final int Function() startPage;

  /// Fraction of a page that must be dragged before it turns.
  final double switchFraction;

  const SensitivePagePhysics({
    required this.startPage,
    this.switchFraction = 0.15,
    super.parent,
  });

  @override
  SensitivePagePhysics applyTo(ScrollPhysics? ancestor) => SensitivePagePhysics(
        startPage: startPage,
        switchFraction: switchFraction,
        parent: buildParent(ancestor),
      );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Let the parent handle overscroll at the edges.
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final start = startPage();
    final dragged = position.pixels / position.viewportDimension - start;

    final int target;
    if (velocity.abs() > tolerance.velocity) {
      target = start + (velocity > 0 ? 1 : -1);
    } else if (dragged.abs() > switchFraction) {
      target = start + (dragged > 0 ? 1 : -1);
    } else {
      target = start;
    }

    final targetPixels = target * position.viewportDimension;
    if ((targetPixels - position.pixels).abs() < tolerance.distance) return null;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

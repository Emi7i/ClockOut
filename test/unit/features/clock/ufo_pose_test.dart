import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/features/clock/widgets/scene/scene_timeline.dart';
import 'package:clock_app/features/clock/widgets/scene/ufo_pose.dart';

void main() {
  test('the intro lands exactly on the left end of the orbit', () {
    final end = UfoPose.intro(1);
    final start = UfoOrbit.poseAt(0);
    expect((end.saucerCenter - UfoOrbit.saucerAt(0)).distance, lessThan(0.01));
    expect((end.translation - start.translation).distance, lessThan(0.01));
    expect(end.rotation, closeTo(start.rotation, 1e-6));
    expect(end.bottomBlend, 1);
  });

  test('the intro has fully settled at settledAt (reverse can start there)',
      () {
    final settled = UfoPose.intro(ShiftTimeline.settledAt);
    final end = UfoPose.intro(1);
    expect((settled.translation - end.translation).distance, lessThan(0.05));
    expect(settled.rotation, closeTo(end.rotation, 1e-3));
    expect(settled.scale, closeTo(end.scale, 1e-6));
    expect(ShiftTimeline.beamOpacity(ShiftTimeline.settledAt), 1);
    expect(ShiftTimeline.ringFade(ShiftTimeline.settledAt), closeTo(1, 1e-3));
    // And nothing moves between there and the end.
    expect(UfoPose.intro(0.95).translation, end.translation);
  });

  test('the intro starts above the card, untouched', () {
    final p = UfoPose.intro(0);
    expect(p.translation.distance, 0);
    expect(p.rotation, 0);
    expect(p.scale, 1);
    expect(p.bottomBlend, 0);
    // The saucer sits where Figma puts it: box origin + saucer offset.
    final expected = UfoGeometry.box.topLeft + UfoGeometry.saucer.center;
    expect((p.saucerCenter - expected).distance, lessThan(0.01));
    expect(expected.dx, closeTo(193.75, 0.1));
    expect(expected.dy, closeTo(236.15, 0.1));
  });

  test('the Figma intro keeps its original end, the landing only nudges it',
      () {
    // The untouched Figma keyframes ended at about (23.9, 666.6); the
    // landing point on the higher ring must be close to it horizontally.
    final end = UfoPose.intro(1).saucerCenter;
    expect(end.dx, closeTo(34, 0.5));
    expect(end.dy, lessThan(666.6));
  });

  test('the right end is the mirror image of the left end', () {
    final l = UfoOrbit.saucerAt(0);
    final r = UfoOrbit.saucerAt(1);
    expect(l.dx + r.dx, closeTo(2 * UfoGeometry.ringCenter.dx, 1e-6));
    expect(l.dy, closeTo(r.dy, 1e-6));
    expect(UfoOrbit.poseAt(0).rotation, closeTo(-UfoOrbit.poseAt(1).rotation, 1e-6));
  });

  test('the UFO is level at the top of the arc and banks along the tangent',
      () {
    expect(UfoOrbit.poseAt(0.5).rotation, closeTo(0, 1e-6));
    expect(UfoOrbit.poseAt(0).rotation, lessThan(0));
    expect(UfoOrbit.poseAt(1).rotation, greaterThan(0));
  });

  group('clock-out loop', () {
    final rightEnd = UfoGeometry.orbitEndAngle;

    test('starts where the UFO was and ends exactly on the intro end pose',
        () {
      for (final f in [0.0, 0.3, 1.0]) {
        final from = UfoOrbit.angleAt(f);
        final first = UfoOrbit.loopPose(from, 0);
        final last = UfoOrbit.loopPose(from, 1);
        expect((first.saucerCenter - UfoOrbit.saucerAt(f)).distance,
            lessThan(0.01));
        expect((last.translation - UfoPose.intro(1).translation).distance,
            lessThan(0.01));
        expect(last.rotation, closeTo(UfoPose.intro(1).rotation, 1e-6));
      }
    });

    test('keeps going clockwise: off the right edge, under, back in on the left',
        () {
      final xs = [
        for (var i = 0; i <= 200; i++)
          UfoOrbit.loopPose(rightEnd, i / 200).saucerCenter,
      ];
      // Leaves the screen on the right, passes below it, comes back from the
      // left.
      expect(xs.any((p) => p.dx > 388 + 20), isTrue);
      expect(xs.any((p) => p.dy > 764 + 20), isTrue);
      expect(xs.any((p) => p.dx < -20), isTrue);
      // The very last stretch arrives from the left edge.
      expect(xs[xs.length - 2].dx, lessThan(xs.last.dx));
      expect(xs.last.dx, closeTo(UfoGeometry.orbitLeftX, 0.5));
    });

    test('a shorter lap covers proportionally less ring', () {
      final left = UfoOrbit.angleAt(0);
      expect(UfoOrbit.loopSweep(left), greaterThan(UfoOrbit.loopSweep(rightEnd)));
      expect(UfoOrbit.loopSweep(rightEnd), UfoOrbit.fullLoopSweep);
      expect(UfoOrbit.fullLoopSweep, lessThan(2 * 3.141592653589793));
    });
  });

  test('the whole arc stays clear of the Earth', () {
    for (var i = 0; i <= 100; i++) {
      final p = UfoOrbit.saucerAt(i / 100);
      final dx = (p.dx - UfoGeometry.earthCenter.dx) / UfoGeometry.earthRadiusX;
      final dy = (p.dy - UfoGeometry.earthCenter.dy) / UfoGeometry.earthRadiusY;
      expect(dx * dx + dy * dy, greaterThan(1.1), reason: 'at f=${i / 100}');
    }
  });
}

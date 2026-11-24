import 'package:flutter_test/flutter_test.dart';
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

  test('the whole arc stays clear of the Earth', () {
    for (var i = 0; i <= 100; i++) {
      final p = UfoOrbit.saucerAt(i / 100);
      final dx = (p.dx - UfoGeometry.earthCenter.dx) / UfoGeometry.earthRadiusX;
      final dy = (p.dy - UfoGeometry.earthCenter.dy) / UfoGeometry.earthRadiusY;
      expect(dx * dx + dy * dy, greaterThan(1.1), reason: 'at f=${i / 100}');
    }
  });
}

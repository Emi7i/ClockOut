import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/features/clock/widgets/scene/scene_swipe.dart';

void main() {
  test('up goes to Night, down goes to Day', () {
    expect(sceneTargetForSwipe(-60), SceneTarget.night);
    expect(sceneTargetForSwipe(60), SceneTarget.day);
  });

  test('tiny movements are ignored', () {
    expect(sceneTargetForSwipe(0), isNull);
    expect(sceneTargetForSwipe(-10), isNull);
    expect(sceneTargetForSwipe(10), isNull);
  });

  test('length does not change the target', () {
    expect(sceneTargetForSwipe(-30), SceneTarget.night);
    expect(sceneTargetForSwipe(-900), SceneTarget.night);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:clock_app/features/clock/widgets/scene/scene_swipe.dart';

void main() {
  SceneTarget day({required double p, bool? up}) => decideSceneTarget(
      progress: p, startedAtNight: false, movingTowardNight: up);
  SceneTarget night({required double p, bool? up}) => decideSceneTarget(
      progress: p, startedAtNight: true, movingTowardNight: up);

  group('from Day', () {
    test('past the commit point always finishes to Night', () {
      expect(day(p: 0.6, up: true), SceneTarget.night);
      expect(day(p: 0.9, up: false), SceneTarget.night); // even if last move was down
    });
    test('before the commit point follows the last movement', () {
      expect(day(p: 0.3, up: true), SceneTarget.night);
      expect(day(p: 0.3, up: false), SceneTarget.day);
    });
    test('no movement settles back to Day', () {
      expect(day(p: 0.2), SceneTarget.day);
    });
  });

  group('from Night (mirrored)', () {
    test('past the mirrored commit point always returns to Day', () {
      expect(night(p: 0.4, up: false), SceneTarget.day);
      expect(night(p: 0.1, up: true), SceneTarget.day);
    });
    test('before it follows the last movement', () {
      expect(night(p: 0.7, up: false), SceneTarget.day);
      expect(night(p: 0.7, up: true), SceneTarget.night);
    });
    test('no movement settles back to Night', () {
      expect(night(p: 0.8), SceneTarget.night);
    });
  });
}

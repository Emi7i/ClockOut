import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clock_app/features/clock/widgets/scene/scene_swipe.dart';

class _Host extends StatefulWidget {
  final void Function(AnimationController) onReady;
  final VoidCallback onTap;
  const _Host({required this.onReady, required this.onTap});
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late final c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1396));
  @override
  void initState() {
    super.initState();
    widget.onReady(c);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: SceneSwipe(
          controller: c,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
}

void main() {
  late AnimationController c;
  var taps = 0;

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(400, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    taps = 0;
    await t.pumpWidget(_Host(onReady: (x) => c = x, onTap: () => taps++));
  }

  /// Swipes [px] vertically (negative = up) in a given number of steps.
  Future<void> swipe(WidgetTester t, double px, {int steps = 1}) async {
    final g = await t.startGesture(const Offset(300, 700));
    await g.moveBy(Offset(0, px.sign * 30)); // past touch slop
    for (var i = 0; i < steps; i++) {
      await g.moveBy(Offset(0, px / steps));
    }
    await t.pump();
    await g.up();
  }

  testWidgets('the scene does not follow the finger', (t) async {
    await pump(t);
    final g = await t.startGesture(const Offset(300, 700));
    await g.moveBy(const Offset(0, -20)); // just past touch slop, below threshold
    await t.pump();
    expect(c.value, 0.0);
    expect(c.isAnimating, isFalse);
    await g.up();
  });

  testWidgets('swipe up plays to Night at the set speed', (t) async {
    await pump(t);
    await swipe(t, -100);
    expect(c.isAnimating, isTrue);
    await t.pump(const Duration(milliseconds: 698)); // half of 1396 ms
    expect(c.value, closeTo(0.5, 0.05));
    await t.pumpAndSettle();
    expect(c.value, 1.0);
  });

  testWidgets('swipe speed and length do not change the animation',
      (t) async {
    await pump(t);
    await swipe(t, -800, steps: 1); // long and fast
    await t.pump(const Duration(milliseconds: 698));
    final fast = c.value;
    await t.pumpAndSettle();

    await pump(t);
    c.value = 0; // the host State is reused between pumps
    await swipe(t, -40, steps: 20); // short and slow
    await t.pump(const Duration(milliseconds: 698));
    final slow = c.value;
    expect(slow, closeTo(fast, 0.03));
    await t.pumpAndSettle();
  });

  testWidgets('swipe down on Night plays back to Day', (t) async {
    await pump(t);
    c.value = 1.0;
    await swipe(t, 100);
    await t.pumpAndSettle();
    expect(c.value, 0.0);
  });

  testWidgets('swipe down on Day and swipe up on Night do nothing',
      (t) async {
    await pump(t);
    await swipe(t, 100);
    await t.pumpAndSettle();
    expect(c.value, 0.0);
    c.value = 1.0;
    await swipe(t, -100);
    await t.pumpAndSettle();
    expect(c.value, 1.0);
  });

  testWidgets('a swipe the other way mid-animation turns it around',
      (t) async {
    await pump(t);
    await swipe(t, -100);
    await t.pump(const Duration(milliseconds: 500));
    final mid = c.value;
    expect(mid, inExclusiveRange(0.2, 0.6));
    await swipe(t, 100);
    await t.pump(const Duration(milliseconds: 100));
    expect(c.value, lessThan(mid));
    await t.pumpAndSettle();
    expect(c.value, 0.0);
  });

  testWidgets('a tap does not move the scene', (t) async {
    await pump(t);
    await t.tapAt(const Offset(200, 400));
    await t.pumpAndSettle();
    expect(c.value, 0.0);
    expect(taps, 1);
  });
}

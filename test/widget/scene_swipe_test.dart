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

  // 800px screen, travel = 0.5 * 800 = 400px for a full swipe.
  Future<TestGesture> dragUp(WidgetTester t, double px) async {
    final g = await t.startGesture(const Offset(300, 700));
    await g.moveBy(const Offset(0, -30)); // past touch slop
    await t.pump();
    await g.moveBy(Offset(0, -px));
    await t.pump();
    return g;
  }

  testWidgets('progress follows the finger and does not auto-complete',
      (t) async {
    await pump(t);
    final g = await dragUp(t, 500); // more than a full travel
    expect(c.value, 1.0); // clamped, finger still down
    expect(c.isAnimating, isFalse);
    await g.up();
    await t.pumpAndSettle();
    expect(c.value, 1.0);
  });

  testWidgets('short upward swipe (before commit) still finishes to Night',
      (t) async {
    await pump(t);
    final g = await dragUp(t, 60);
    expect(c.value, inInclusiveRange(0.05, 0.3));
    await g.up();
    await t.pumpAndSettle();
    expect(c.value, 1.0);
  });

  testWidgets('swiping up then back down before commit returns to Day',
      (t) async {
    await pump(t);
    final g = await dragUp(t, 100);
    await g.moveBy(const Offset(0, 40)); // last movement: down
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
    expect(c.value, 0.0);
  });

  testWidgets('past the commit point finishes even if last move was down',
      (t) async {
    await pump(t);
    final g = await dragUp(t, 300); // ~0.82
    await g.moveBy(const Offset(0, 20));
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
    expect(c.value, 1.0);
  });

  testWidgets('mirrored on Night: swipe down returns to Day', (t) async {
    await pump(t);
    c.value = 1.0;
    final g = await t.startGesture(const Offset(300, 300));
    await g.moveBy(const Offset(0, 30));
    await t.pump();
    await g.moveBy(const Offset(0, 260)); // ~ -0.65 -> progress ~0.3
    await t.pump();
    await g.up();
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

  testWidgets('catching the scene mid-animation interrupts it', (t) async {
    await pump(t);
    c.forward();
    await t.pump(const Duration(milliseconds: 400));
    final mid = c.value;
    final g = await t.startGesture(const Offset(300, 700));
    await g.moveBy(const Offset(0, 30));
    await t.pump();
    expect(c.isAnimating, isFalse);
    expect(c.value, closeTo(mid, 0.06));
    await g.up();
    await t.pumpAndSettle();
  });
}

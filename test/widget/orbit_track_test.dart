import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:clock_app/common_widgets/orbit_track.dart';

void main() {
  // A straight 200 px line from (50, 100) to (250, 100).
  final line = Path()
    ..moveTo(50, 100)
    ..lineTo(250, 100);

  Future<Offset> bodyAt(WidgetTester t, double progress) async {
    final key = GlobalKey();
    await t.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 300,
        height: 200,
        child: OrbitTrack(
          path: line,
          progress: progress,
          bodyBuilder: (_, __) => SizedBox(key: key, width: 4, height: 4),
        ),
      ),
    ));
    final box = key.currentContext!.findRenderObject() as RenderBox;
    return box.localToGlobal(Offset.zero);
  }

  testWidgets('the body sits on the path at its progress', (t) async {
    expect(await bodyAt(t, 0), const Offset(50, 100));
    expect(await bodyAt(t, 0.25), const Offset(100, 100));
    expect(await bodyAt(t, 1), const Offset(250, 100));
  });

  testWidgets('changing the progress moves the body', (t) async {
    final a = await bodyAt(t, 0.2);
    final b = await bodyAt(t, 0.7);
    expect(b.dx - a.dx, closeTo(100, 0.01));
  });

  testWidgets('progress outside 0..1 is clamped to the ends', (t) async {
    expect(await bodyAt(t, -1), const Offset(50, 100));
    expect(await bodyAt(t, 2), const Offset(250, 100));
  });

  testWidgets('the body is told the heading of the path', (t) async {
    double? heading;
    final diagonal = Path()
      ..moveTo(0, 0)
      ..lineTo(100, 100);
    await t.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 200,
        height: 200,
        child: OrbitTrack(
          path: diagonal,
          progress: 0.5,
          bodyBuilder: (_, h) {
            heading = h;
            return const SizedBox();
          },
        ),
      ),
    ));
    expect(heading, closeTo(0.7853981634, 1e-6)); // 45° towards the bottom
    expect(pathHeadingAt(diagonal, 0.5), closeTo(0.7853981634, 1e-6));
  });

  testWidgets('the line never swallows touches meant for what is underneath',
      (t) async {
    var taps = 0;
    await t.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 300,
        height: 200,
        child: Stack(children: [
          // A button at the bottom of the stack...
          Positioned(
            left: 10,
            top: 10,
            width: 50,
            height: 50,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox.expand(),
            ),
          ),
          // ...under a track that covers the whole area.
          Positioned.fill(
            child: OrbitTrack(
              path: line,
              progress: 0.5,
              bodyBuilder: (_, __) => const SizedBox(),
            ),
          ),
        ]),
      ),
    ));
    await t.tapAt(const Offset(30, 30));
    expect(taps, 1);
  });
}

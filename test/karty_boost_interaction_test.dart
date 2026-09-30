import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/karty_boost_button_affordance.dart';
import 'package:lingualloop/ui/widgets/karty_boost_edge_meter.dart';

void main() {
  testWidgets('Köşe sabit kalır; sürükleme boost başlatmaz', (tester) async {
    final progress = ValueNotifier<double>(0);
    final top = GlobalKey();
    final bottom = GlobalKey();
    var taps = 0;
    var swipes = 0;
    addTearDown(progress.dispose);

    Widget frame(
            {bool ready = false,
            bool active = false,
            bool activating = false}) =>
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GestureDetector(
                onPanEnd: (_) => swipes++,
                child: SizedBox(
                  width: 280,
                  height: 420,
                  child: KartyBoostEdgeMeter(
                    scale: 320 / 750,
                    charge: ready ? 5 : 3,
                    chargeGoal: 5,
                    isReady: ready,
                    isActive: active,
                    isActivating: activating,
                    boostProgress: progress,
                    onTap: () => taps++,
                    topLeftAnchorKey: top,
                    bottomRightAnchorKey: bottom,
                  ),
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(frame());
    final initial = tester.getCenter(find.byKey(bottom));
    await tester.tap(find.byType(KartyBoostButtonAffordance));
    expect(taps, 0);

    await tester.pumpWidget(frame(ready: true));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.getCenter(find.byKey(bottom)), initial);
    final hitSize = tester.getSize(find.byType(KartyBoostButtonAffordance));
    expect(hitSize.width, greaterThanOrEqualTo(44));
    expect(hitSize.height, greaterThanOrEqualTo(44));
    expect(find.text('BOOST  ×3'), findsNothing);
    expect(find.text('3 kat puan için dokun ↘'), findsNothing);

    await tester.tapAt(tester.getCenter(find.byKey(top)));
    expect(taps, 0);
    final swipesBeforeDrag = swipes;
    await tester.drag(
        find.byType(KartyBoostButtonAffordance), const Offset(-80, 0));
    await tester.pump();
    expect(swipes, swipesBeforeDrag + 1);
    expect(taps, 0);
    await tester.tap(find.byType(KartyBoostButtonAffordance));
    expect(taps, 1);

    await tester.pumpWidget(frame(activating: true));
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getCenter(find.byKey(bottom)), initial);
    await tester.pumpWidget(frame(active: true));
    await tester.tap(find.byType(KartyBoostButtonAffordance));
    expect(taps, 1);
    await tester.pumpWidget(frame(ready: true));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('3 kat puan için dokun ↘'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/pressable_layered_card.dart';

void main() {
  testWidgets(
      'kart etkinleşirken yükselir ve etkinliğini kaybedince geri çöker',
      (tester) async {
    var enabled = false;
    var taps = 0;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: PressableLayeredCard(
                  width: 200,
                  height: 108,
                  shadowOffset: 8,
                  radius: BorderRadius.circular(20),
                  baseColor: Colors.blue.shade900,
                  onPressed: enabled ? () => taps++ : null,
                  face: const ColoredBox(
                    key: Key('card-face'),
                    color: Colors.blue,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final disabledTop =
        tester.getTopLeft(find.byKey(const Key('card-face'))).dy;
    await tester.tap(find.byType(PressableLayeredCard));
    expect(taps, 0);

    updateHost(() => enabled = true);
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const Key('card-face'))).dy,
      disabledTop,
    );

    await tester.pump(const Duration(milliseconds: 40));
    final transitionTop =
        tester.getTopLeft(find.byKey(const Key('card-face'))).dy;
    expect(transitionTop, lessThan(disabledTop));
    expect(transitionTop, greaterThan(disabledTop - 8));

    await tester.pump(const Duration(milliseconds: 260));
    final enabledTop = tester.getTopLeft(find.byKey(const Key('card-face'))).dy;
    expect(
      enabledTop,
      moreOrLessEquals(disabledTop - 8, epsilon: 0.01),
    );
    await tester.tap(find.byType(PressableLayeredCard));
    expect(taps, 1);

    updateHost(() => enabled = false);
    await tester.pump();

    // Dokunma ilk karede kapanır; yüz ise henüz aktif konumundan
    // ayrılmamıştır ve görsel çöküş buradan başlar.
    expect(
      tester.getTopLeft(find.byKey(const Key('card-face'))).dy,
      moreOrLessEquals(enabledTop, epsilon: 0.01),
    );
    await tester.tap(find.byType(PressableLayeredCard));
    expect(taps, 1);

    await tester.pump(const Duration(milliseconds: 190));
    final sinkingTop = tester.getTopLeft(find.byKey(const Key('card-face'))).dy;
    expect(sinkingTop, greaterThan(enabledTop));
    expect(sinkingTop, lessThan(disabledTop));

    await tester.pump(const Duration(milliseconds: 250));
    expect(
      tester.getTopLeft(find.byKey(const Key('card-face'))).dy,
      moreOrLessEquals(disabledTop, epsilon: 0.01),
    );
  });
}

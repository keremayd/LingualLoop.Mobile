import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/models/karty_path.dart';
import 'package:stelinda/ui/screens/karty_path_screen.dart';

import 'helpers/karty_path_preview.dart';

/// "Bulunduğun desteye dön" düğmesi (16 Kas 2026): şu anki deste ekrandayken
/// görünmez; kaydırıp uzaklaşınca belirir, ok destenin kaldığı yöne bakar;
/// dokununca kamera desteye döner ve düğme söner.
void main() {
  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyUnit doneUnit(int number) => KartyUnit(
        number: number,
        title: 'Ünite $number',
        state: KartyUnitState.done,
        wordCount: 24,
        consolidatedCount: 22,
        emblem: img('haus'),
        steps: [
          for (var deck = 1; deck <= 3; deck++)
            KartyStep(state: KartyStepState.done, deck: deck, label: 'D$deck'),
        ],
      );

  final data = KartyPathData(
    units: [
      doneUnit(1),
      doneUnit(2),
      KartyUnit(
        number: 3,
        title: 'Ünite 3',
        state: KartyUnitState.current,
        wordCount: 24,
        emblem: img('koffer'),
        steps: const [
          KartyStep(state: KartyStepState.done, deck: 1, label: 'D1'),
          KartyStep(state: KartyStepState.current, deck: 2, label: 'D2'),
          KartyStep(state: KartyStepState.upcoming, deck: 3, label: 'D3'),
        ],
      ),
      KartyUnit(
        number: 4,
        title: 'Ünite 4',
        state: KartyUnitState.locked,
        wordCount: 24,
        emblem: img('buch'),
        steps: const [
          KartyStep(state: KartyStepState.locked, deck: 1),
          KartyStep(state: KartyStepState.locked, deck: 2),
        ],
      ),
    ],
  );

  final button = find.byKey(const ValueKey('back-to-current'));

  double opacity(WidgetTester tester) =>
      tester.widget<AnimatedOpacity>(button).opacity;

  int quarterTurns(WidgetTester tester) => tester
      .widget<RotatedBox>(
          find.descendant(of: button, matching: find.byType(RotatedBox)))
      .quarterTurns;

  testWidgets('uzaklaşınca belirir, ok yönü doğru, dokununca desteye döner',
      (tester) async {
    tester.view.physicalSize = const Size(402, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: KartyPathScreen(
        data: data,
        header: previewPathHeader,
        stations: previewStations(),
        onContinue: () {},
        controller: controller,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Açılışta deste ortada: düğme yok.
    final home = controller.offset;
    expect(home, greaterThan(0));
    expect(opacity(tester), 0);

    // Geçmişe (başa) kaydırınca deste aşağıda kalır: ok aşağı.
    controller.jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity(tester), 1);
    expect(quarterTurns(tester), 3);

    // Dokununca kamera açılıştaki yere döner, düğme söner.
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(controller.offset, moreOrLessEquals(home, epsilon: 1));
    expect(opacity(tester), 0);

    // İleriye (sona) kaydırınca deste yukarıda kalır: ok yukarı.
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity(tester), 1);
    expect(quarterTurns(tester), 1);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(controller.offset, moreOrLessEquals(home, epsilon: 1));
    expect(opacity(tester), 0);
  });
}

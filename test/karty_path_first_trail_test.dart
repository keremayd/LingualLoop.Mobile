import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/models/karty_path.dart';
import 'package:stelinda/ui/screens/karty_path_screen.dart';
import 'package:stelinda/ui/widgets/karty_unit_header.dart';

import 'helpers/karty_path_preview.dart';

/// Karttan ilk desteye inen yol her ünitede aynı (kullanıcı, 16 ve 18 Kas
/// 2026: "her ünitenin patika izleri aynı olmalı"). İlk deste şu anki deste
/// olsa da halkasının tepesi, sıradan bir ilk destenin yüzünün tepesiyle
/// aynı yerde durur; yol da aynı noktaya varır. Şu anki ilk deste bir dönem
/// 120 birim fazladan pay alıyordu: Ünite 1'in yolu Ünite 2'ninkinden uzundu
/// ve desteden uzakta bitiyordu.
void main() {
  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyStep deck(KartyStepState state, int number) =>
      KartyStep(state: state, deck: number, label: 'Deste $number');

  final data = KartyPathData(
    units: [
      KartyUnit(
        number: 1,
        title: 'Evde',
        state: KartyUnitState.done,
        wordCount: 16,
        consolidatedCount: 15,
        emblem: img('haus'),
        steps: [
          deck(KartyStepState.done, 1),
          deck(KartyStepState.done, 2),
        ],
      ),
      KartyUnit(
        number: 2,
        title: 'Sofrada',
        state: KartyUnitState.current,
        wordCount: 16,
        emblem: img('brot'),
        steps: [
          deck(KartyStepState.current, 1),
          deck(KartyStepState.upcoming, 2),
        ],
      ),
      KartyUnit(
        number: 3,
        title: 'Yolculuk',
        state: KartyUnitState.locked,
        wordCount: 16,
        emblem: img('koffer'),
        steps: [
          deck(KartyStepState.locked, 1),
          deck(KartyStepState.locked, 2),
        ],
      ),
    ],
  );

  testWidgets('karttan ilk desteye her ünitede aynı mesafe', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: KartyPathScreen(
        data: data,
        header: previewPathHeader,
        stations: previewStations(),
        onContinue: () {},
      ),
    ));
    await tester.pump();
    await tester.pump();

    const s = 402 / 750;
    Rect rectOf(Element element) {
      final box = element.renderObject! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    // Ünitenin listedeki kartı; ilk ünitenin yapışan kopyası aynı yerde.
    double cardBottom(int unit) => tester
        .getRect(find
            .byWidgetPredicate(
                (w) => w is KartyUnitHeader && w.unit.number == unit)
            .last)
        .bottom;

    // İlk desteler yukarıdan aşağı ünite sırasıyla.
    final firsts = [
      for (final element in find
          .byWidgetPredicate((w) => w.runtimeType.toString() == '_PathNode')
          .evaluate())
        if (((element.widget as dynamic).step as KartyStep).deck == 1)
          (
            step: (element.widget as dynamic).step as KartyStep,
            rect: rectOf(element),
          ),
    ]..sort((a, b) => a.rect.top.compareTo(b.rect.top));
    expect(firsts, hasLength(3));

    // Destenin tepesi; şu anki destede kelime halkasının dış kenarı
    // (yüzden 16 boşluk + 12 kalınlığın yarısı).
    double gap(int unit) {
      final first = firsts[unit - 1];
      final ringed = first.step.state == KartyStepState.current &&
          first.step.newGoal > 0;
      final top = first.rect.top - (ringed ? (16 + 12 / 2) * s : 0);
      return top - cardBottom(unit);
    }

    expect(firsts[1].step.state, KartyStepState.current);
    expect(gap(2), closeTo(gap(3), 0.5));
    expect(gap(1), closeTo(gap(3), 0.5));
  });
}

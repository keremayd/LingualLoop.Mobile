import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';

/// Ünite açılışından sonra patikaya geliş bitince açılan ünitenin başlığı
/// üste oturur ve yapışan başlık o olur. Kamera yerinde kalsaydı önceki
/// ünitenin başlığı yarı saydam belirip kapının üstüne binerdi.
void main() {
  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyPathData sample() => KartyPathData(
        tickets: 11,
        units: [
          KartyUnit(
            number: 1,
            title: 'Evde',
            state: KartyUnitState.done,
            wordCount: 16,
            consolidatedCount: 13,
            emblem: img('haus'),
            steps: const [
              KartyStep(state: KartyStepState.done, deck: 1, label: 'Deste 1'),
              KartyStep(state: KartyStepState.done, deck: 2, label: 'Deste 2'),
            ],
          ),
          KartyUnit(
            number: 2,
            title: 'Yolculuk',
            state: KartyUnitState.current,
            wordCount: 12,
            emblem: img('koffer'),
            steps: const [
              KartyStep(
                state: KartyStepState.current,
                deck: 1,
                label: 'Deste 1',
                reviewCount: 4,
              ),
              KartyStep(
                state: KartyStepState.upcoming,
                deck: 2,
                label: 'Deste 2',
                newGoal: 4,
              ),
            ],
          ),
          KartyUnit(
            number: 3,
            title: 'Yemek',
            state: KartyUnitState.locked,
            wordCount: 14,
            emblem: img('apfel'),
            steps: const [
              KartyStep(state: KartyStepState.locked),
              KartyStep(state: KartyStepState.locked),
            ],
          ),
        ],
      );

  testWidgets('geliş bitince açılan ünite yapışan başlık olur', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final data = sample();
    int? arrivalUnit = 2;
    var play = false;
    var done = false;
    late StateSetter setPage;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setPage = setState;
            return KartyPathScreen(
              data: data,
              onBack: () {},
              onContinue: () {},
              scrollToCurrent: false,
              arrivalUnit: arrivalUnit,
              playArrival: play,
              onArrivalDone: () => setState(() {
                arrivalUnit = null;
                play = false;
                done = true;
              }),
            );
          },
        ),
      ),
    );
    await tester.pump();

    setPage(() => play = true);
    await tester.pump();
    // Kamera (en çok 1.4 sn) + gösteri (3.2 sn) + duruş + yerine oturma.
    for (var i = 0; i < 80 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(done, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    // Yeni ünitenin başlığı hem yerinde hem yapışan başlıkta; önceki
    // ünitenin başlığı yalnız patikadaki yerinde (ekranın üstünde, görünmez).
    expect(find.text('Yolculuk'), findsNWidgets(2));
    expect(find.text('Evde'), findsOneWidget);

    // İkisi aynı yerde buluşur: yapışan başlık yerindekini birebir örter.
    final titles = find.text('Yolculuk');
    final inPath = tester.getTopLeft(titles.first);
    final pinned = tester.getTopLeft(titles.last);
    expect(inPath.dx, moreOrLessEquals(pinned.dx, epsilon: 0.01));
    expect(inPath.dy, moreOrLessEquals(pinned.dy, epsilon: 0.01));
  });
}

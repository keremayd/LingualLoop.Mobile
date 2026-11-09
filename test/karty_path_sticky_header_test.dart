import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';
import 'package:lingualloop/ui/widgets/karty_unit_header.dart';
import 'package:lingualloop/ui/widgets/practice_station_marks.dart';

import 'helpers/karty_path_preview.dart';

/// Yapışan ünite başlığı: iki ünitenin başlığı hiçbir kaydırma konumunda üst
/// üste binmez. Sekmeden dönünce patika açılan ünitenin başlığı altında kalıyor,
/// önceki ünite tepede yapışık görünüyordu (kullanıcı, 6 Kas 2026).
void main() {
  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyPathData sample({int currentDeck = 1}) => KartyPathData(
        units: [
          KartyUnit(
            number: 1,
            title: 'Evde',
            state: KartyUnitState.done,
            wordCount: 16,
            consolidatedCount: 15,
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
            wordCount: 16,
            emblem: img('koffer'),
            steps: [
              KartyStep(
                state: currentDeck == 1
                    ? KartyStepState.current
                    : KartyStepState.done,
                deck: 1,
                label: 'Deste 1',
              ),
              KartyStep(
                state: currentDeck == 2
                    ? KartyStepState.current
                    : KartyStepState.upcoming,
                deck: 2,
                label: 'Deste 2',
              ),
            ],
          ),
        ],
      );

  Future<ScrollController> pump(
    WidgetTester tester,
    KartyPathData data, {
    double height = 760,
  }) async {
    tester.view.physicalSize = Size(402, height);
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
    await tester.pump();
    return controller;
  }

  testWidgets('ilk destesindeki ünitenin başlığı üste oturur', (tester) async {
    await pump(tester, sample());

    // Yapışan başlık şu anki ünite: yerindekiyle aynı konumda.
    final titles = find.text('Yolculuk');
    expect(titles, findsNWidgets(2));
    expect(
      tester.getTopLeft(titles.first).dy,
      moreOrLessEquals(tester.getTopLeft(titles.last).dy, epsilon: 0.01),
    );
    // Önceki ünitenin başlığı yalnız patikadaki yerinde, ekranın üstünde.
    expect(find.text('Evde'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Evde')).dy, lessThan(0));
  });

  testWidgets('sıradaki başlık yapışan başlığı önünden iter', (tester) async {
    final controller = await pump(tester, sample());
    final headers = find.byType(KartyUnitHeader);
    final docked = controller.offset;

    // Başlığı üste oturmadan önceki bütün kaydırma konumları.
    for (final up in [20.0, 60.0, 100.0, 140.0, 180.0]) {
      controller.jumpTo(docked - up);
      await tester.pump();
      await tester.pump();

      final next = tester.getRect(headers.at(1));
      final pinned = tester.getRect(headers.last);
      expect(find.text('Evde'), findsNWidgets(2), reason: '$up yukarıda');
      expect(
        pinned.bottom,
        lessThanOrEqualTo(next.top + 0.5),
        reason: '$up yukarıda başlıklar üst üste biniyor',
      );
      // İtilen başlık üst şeridin üstüne çıkmaz: alanında kesilir.
      expect(
        find.ancestor(of: headers.last, matching: find.byType(ClipRect)),
        findsWidgets,
      );
    }
  });

  testWidgets('yapışan başlığın arkasında yalnız üst köşeler örtülür',
      (tester) async {
    await pump(tester, sample());
    final headers = find.byType(KartyUnitHeader);
    final layer = find
        .ancestor(of: headers.last, matching: find.byType(AnimatedOpacity))
        .first;
    final backing = find.descendant(
      of: layer,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox && widget.color == const Color(0xFF041227),
      ),
    );

    // Kartın altında yolu kesen zemin bandı olmamalı.
    expect(backing, findsOneWidget);
    expect(
      tester.getRect(backing).bottom,
      lessThan(tester.getRect(headers.last).center.dy),
    );
  });

  testWidgets('deste bitince patika yeni desteye kayar', (tester) async {
    // Kısa ekran: yeni deste ilk konumda ekranın altında kalıyor.
    final controller = await pump(tester, sample(), height: 560);
    final before = controller.offset;

    await tester.pumpWidget(MaterialApp(
      home: KartyPathScreen(
        data: sample(currentDeck: 2),
        header: previewPathHeader,
        stations: previewStations(),
        onContinue: () {},
        controller: controller,
      ),
    ));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(controller.offset, greaterThan(before));
    final row = tester.getCenter(find.byType(ArticleDragMark));
    expect(row.dy, inInclusiveRange(0, 560));
  });
}

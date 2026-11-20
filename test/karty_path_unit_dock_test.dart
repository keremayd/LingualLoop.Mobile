import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/models/karty_path.dart';
import 'package:stelinda/ui/screens/karty_path_screen.dart';
import 'package:stelinda/ui/widgets/karty_unit_header.dart';

import 'helpers/karty_path_preview.dart';

/// Ünite başlıklarında görünmeyen çukur (kullanıcı, 15 Kas 2026): kaydırma
/// başlığın oturduğu yerin yakınında biterse başlık tepeye çekilir ve
/// oturunca haber verilir (titreşim). Yaklaşırken kartın %65'i; önceki
/// ünitenin kapısı yapışan kartın altına girdiyse (iki kart alt alta)
/// uzaklık ne olursa olsun, iki yönden de; kapı görünürken çekmez. Geçince
/// kartın %35'i: az geçen geri döner, ilerleyen ya da hızlı giden geçer.
/// Kameranın konumlandırması çekilmez.
void main() {
  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  final data = KartyPathData(units: [
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
      steps: const [
        KartyStep(state: KartyStepState.current, deck: 1, label: 'Deste 1'),
        KartyStep(state: KartyStepState.upcoming, deck: 2, label: 'Deste 2'),
        KartyStep(state: KartyStepState.upcoming, deck: 3, label: 'Deste 3'),
      ],
    ),
  ]);

  /// Ünite 2'nin başlığının tepeye oturduğu kaydırma konumu.
  late double dock;
  const scale = 402 / 750;
  const near = KartyUnitHeader.height * 0.65 * scale;
  const below = KartyUnitHeader.height * 0.35 * scale;

  /// Ünite 1'in kapısı yapışan kartın altına girdiği uzaklık: kart + kapıdan
  /// sonraki yol (Ünite 2'nin başlığı kapının altından 150 birim aşağıda).
  const empty = (KartyUnitHeader.height + 150) * scale;
  var docked = 0;

  Future<ScrollController> pump(WidgetTester tester) async {
    docked = 0;
    tester.view.physicalSize = const Size(402, 737);
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
        onDocked: () => docked++,
      ),
    ));
    await tester.pump();
    await tester.pump();
    final area = tester.getRect(find.byType(SingleChildScrollView));
    controller.jumpTo(0);
    await tester.pump();
    final header = find
        .ancestor(
          of: find.text('Yolculuk'),
          matching: find.byType(KartyUnitHeader),
        )
        .first;
    dock = tester.getRect(header).top - area.top;
    return controller;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> slowDrag(WidgetTester tester, double dy) => tester.timedDrag(
        find.byType(SingleChildScrollView),
        Offset(0, dy),
        const Duration(seconds: 1),
      );

  testWidgets('başlık yerine yaklaşınca oturur ve haber verir', (tester) async {
    final controller = await pump(tester);
    controller.jumpTo(dock - near - 15);
    await tester.pump();
    // Kamera (jumpTo) çekilmez: bıraktığı yerde kalır.
    await settle(tester);
    expect(
      controller.offset,
      moreOrLessEquals(dock - near - 15, epsilon: 0.5),
    );
    expect(docked, 0);

    await slowDrag(tester, -40);
    await settle(tester);
    expect(controller.offset, moreOrLessEquals(dock, epsilon: 0.5));
    expect(docked, 1);
  });

  for (final dy in [-30.0, 30.0]) {
    testWidgets(
        'iki kart alt alta kalınca bırakınca oturur '
        '(${dy < 0 ? 'Ünite 2\'ye' : 'Ünite 1\'e'} doğru)', (tester) async {
      final controller = await pump(tester);
      // Ünite 1'in kapısı kartın altında; başlık tepeden çok uzakta.
      controller.jumpTo(dock - empty + 40);
      await tester.pump();
      await slowDrag(tester, dy);
      await settle(tester);
      expect(controller.offset, moreOrLessEquals(dock, epsilon: 0.5));
      expect(docked, 1);
    });
  }

  testWidgets('önceki ünitenin kapısı görünürken çekmez', (tester) async {
    final controller = await pump(tester);
    controller.jumpTo(dock - empty - 60);
    await tester.pump();
    await slowDrag(tester, -30);
    await settle(tester);
    expect(controller.offset, lessThan(dock - empty));
    expect(docked, 0);
  });

  testWidgets('başlığı biraz geçip bırakınca geri oturur', (tester) async {
    final controller = await pump(tester);
    controller.jumpTo(dock + below * 0.3);
    await tester.pump();
    await slowDrag(tester, -24);
    await settle(tester);
    expect(controller.offset, moreOrLessEquals(dock, epsilon: 0.5));
    expect(docked, 1);
  });

  testWidgets('ünitenin içine ilerleyince çukurdan çıkar', (tester) async {
    final controller = await pump(tester);
    controller.jumpTo(dock + below * 1.5);
    await tester.pump();
    await slowDrag(tester, -30);
    await settle(tester);
    expect(controller.offset, greaterThan(dock + below * 1.5));
    expect(docked, 0);
  });

  testWidgets('hızlı savrulma çukurun üstünden geçer', (tester) async {
    final controller = await pump(tester);
    controller.jumpTo(dock - 200);
    await tester.pump();
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
      2500,
    );
    await settle(tester);
    expect(controller.offset, greaterThan(dock + below));
    expect(docked, 0);
  });
}

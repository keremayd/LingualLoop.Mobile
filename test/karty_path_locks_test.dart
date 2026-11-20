import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/models/karty_path.dart';
import 'package:stelinda/ui/screens/karty_path_screen.dart';
import 'package:stelinda/ui/widgets/karty_unit_marks.dart';
import 'package:stelinda/ui/widgets/quest_icons.dart';

import 'helpers/karty_path_preview.dart';

/// Patikada sırası gelmemiş olan kilit taşır (kullanıcı, 19 Kas 2026):
/// şu anki ünitenin sıradaki destesi de kilitli ünitenin desteleri de;
/// bitmiş ve şu anki deste şimşek taşır. Pekiştirme kapısı da ünitenin
/// desteleri bitene kadar yalnız kilit taşır; desteler bitince (kalan adım
/// yalnız tekrar) dönüş oku, hedefe ulaşınca onay.
void main() {
  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyStep deck(KartyStepState state, int number) =>
      KartyStep(state: state, deck: number, label: 'Deste $number');

  /// Ünite 1 hedefe ulaştı, Ünite 2 şu anki ünite, Ünite 3 kilitli.
  /// [decksDone] ise Ünite 2'nin desteleri bitti, kalan adım yalnız tekrar.
  KartyPathData path({bool decksDone = false}) => KartyPathData(
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
            consolidatedCount: 6,
            emblem: img('brot'),
            steps: decksDone
                ? [
                    deck(KartyStepState.done, 1),
                    deck(KartyStepState.done, 2),
                    const KartyStep(
                      state: KartyStepState.current,
                      label: 'Tekrar',
                      newGoal: 0,
                      reviewCount: 4,
                    ),
                  ]
                : [
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

  Future<void> pumpPath(WidgetTester tester, KartyPathData data) async {
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
  }

  Iterable<Element> nodes(String type) => find
      .byWidgetPredicate((w) => w.runtimeType.toString() == type)
      .evaluate();

  bool has(Element element, Finder matching) => find
      .descendant(of: find.byWidget(element.widget), matching: matching)
      .evaluate()
      .isNotEmpty;

  final lock = find.byType(KartyLockMark);
  final arrow = find.byWidgetPredicate(
    (w) => w is QuestIcon && w.questKey == 'review_two',
  );

  /// Kapılar yukarıdan aşağı: (onay, ok, kilit).
  List<({bool check, bool arrow, bool lock})> gates() => [
        for (final element in nodes('_GateNode'))
          (
            check: (element.widget as dynamic).ready as bool,
            arrow: has(element, arrow),
            lock: has(element, lock),
          ),
      ];

  testWidgets('sırası gelmemiş destede kilit, açılmışta şimşek',
      (tester) async {
    await pumpPath(tester, path());

    final seen = <KartyStepState>{};
    for (final element in nodes('_PathNode')) {
      final step = (element.widget as dynamic).step as KartyStep;
      final waiting = step.state == KartyStepState.upcoming ||
          step.state == KartyStepState.locked;
      expect(has(element, lock), waiting,
          reason: '${step.label} (${step.state.name})');
      seen.add(step.state);
    }
    expect(seen, containsAll(KartyStepState.values));
  });

  testWidgets('desteler bitmeden kapıda kilit', (tester) async {
    await pumpPath(tester, path());

    expect(gates(), [
      (check: true, arrow: false, lock: false),
      (check: false, arrow: false, lock: true),
      (check: false, arrow: false, lock: true),
    ]);
  });

  testWidgets('desteler bitince kapıda dönüş oku', (tester) async {
    await pumpPath(tester, path(decksDone: true));

    expect(gates(), [
      (check: true, arrow: false, lock: false),
      (check: false, arrow: true, lock: false),
      (check: false, arrow: false, lock: true),
    ]);
  });
}

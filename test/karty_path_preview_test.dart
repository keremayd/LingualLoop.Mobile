import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';

import 'helpers/preview_fonts.dart';

/// Karty Yolu prototipinin önizlemesi (örnek veri).
///
///   flutter test --update-goldens test/karty_path_preview_test.dart
///
/// İki pano: kaydırmanın tamamını gösteren uzun patika ve adım pencereleri
/// (geçmiş gün, yarın).
void main() {
  setUpAll(loadPreviewFonts);

  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyWord w(String word, String article, String image, int box,
          {bool due = false}) =>
      KartyWord(
        word: word,
        article: article,
        image: img(image),
        box: box,
        due: due,
      );

  KartyPathData sample() {
    final evde = KartyUnit(
      number: 1,
      title: 'Evde',
      state: KartyUnitState.current,
      wordCount: 40,
      consolidatedCount: 12,
      emblem: img('haus'),
      steps: [
        KartyStep(
          state: KartyStepState.done,
          deck: 1,
          label: 'Deste 1',
          title: 'Deste 1',
          dueCount: 2,
          words: [
            w('Buch', 'das', 'buch', 5),
            w('Tasche', 'die', 'tasche', 4),
            w('Schlüssel', 'der', 'schluessel', 1, due: true),
            w('Klosett', 'das', 'klosett', 1, due: true),
            w('Katze', 'die', 'katze', 3),
            w('Wolke', 'die', 'wolke', 2),
            w('Brot', 'das', 'brot', 2),
            w('Apfel', 'der', 'apfel', 3),
          ],
        ),
        KartyStep(
          state: KartyStepState.done,
          deck: 2,
          label: 'Deste 2',
          title: 'Deste 2',
          dueCount: 3,
          words: [
            w('Haus', 'das', 'haus', 4),
            w('Stuhl', 'der', 'stuhl', 3),
            w('Lampe', 'die', 'lampe', 1, due: true),
            w('Staubsauger', 'der', 'staubsauger', 1, due: true),
            w('Insel', 'die', 'insel', 1, due: true),
            w('Koffer', 'der', 'koffer', 2),
            w('Banane', 'die', 'banane', 2),
            w('Katze', 'die', 'katze', 1),
          ],
        ),
        const KartyStep(
          state: KartyStepState.current,
          deck: 3,
          label: 'Deste 3',
          title: 'Deste 3',
          newCount: 3,
          reviewCount: 5,
        ),
        KartyStep(
          state: KartyStepState.upcoming,
          deck: 4,
          label: 'Deste 4',
          title: 'Deste 4',
          upcoming: [
            for (final name in [
              'apfel',
              'banane',
              'brot',
              'wolke',
              'insel',
              'koffer',
              'katze',
              'klosett',
            ])
              img(name),
          ],
        ),
        const KartyStep(
          state: KartyStepState.upcoming,
          deck: 5,
          label: 'Deste 5',
          title: 'Deste 5',
        ),
      ],
    );
    final yolculuk = KartyUnit(
      number: 2,
      title: 'Yolculuk',
      state: KartyUnitState.locked,
      wordCount: 40,
      emblem: img('koffer'),
      unlockHint: "Evde'nin %80'i pekişince açılır",
      steps: [
        for (var i = 1; i <= 5; i++)
          KartyStep(state: KartyStepState.locked, deck: i),
      ],
    );
    return KartyPathData(tickets: 12, units: [evde, yolculuk]);
  }

  Widget phone({
    required Widget child,
    double height = 932,
  }) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: SizedBox(
          width: 430,
          height: height,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(430, height),
              padding: const EdgeInsets.only(top: 47),
              devicePixelRatio: 2,
            ),
            child: child,
          ),
        ),
      );

  Widget board(List<(String, String, Widget)> frames) => Material(
        color: const Color(0xFF020A18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 34, 40, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (title, subtitle, frame)) in frames.indexed) ...[
                if (i > 0) const SizedBox(width: 40),
                Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: AppTypography.heading,
                        fontFamily: AppTypography.displayFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8FA0B5),
                        fontSize: 16,
                        fontWeight: AppTypography.body,
                        fontFamily: AppTypography.family,
                      ),
                    ),
                    const SizedBox(height: 22),
                    frame,
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  Future<void> render(
    WidgetTester tester,
    Size size,
    Widget child,
    String golden,
  ) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpWidget(
      MaterialApp(debugShowCheckedModeBanner: false, home: child),
    );
    await tester.pump();
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(golden));
  }

  testWidgets('karty yolu — patikanın tamamı', (tester) async {
    const height = 1720.0;
    await render(
      tester,
      const Size(510, height + 180),
      board([
        (
          'Karty Yolu',
          'Kaydırmanın tamamı',
          phone(
            height: height,
            child: Stack(
              children: [
                KartyPathScreen(
                  data: sample(),
                  onBack: () {},
                  onContinue: () {},
                  scrollToCurrent: false,
                ),
                // Uzun görüntünün altı sayfa zeminine söner.
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 140,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00041227), Color(0xFF041227)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
      'goldens/karty_path.png',
    );
  });

  testWidgets('karty yolu — adım pencereleri', (tester) async {
    final data = sample();
    final unit = data.units.first;
    const scale = 430 / 750;

    Widget withSheet(KartyStep step, double offset) => phone(
          child: Stack(
            children: [
              KartyPathScreen(
                data: data,
                onBack: () {},
                onContinue: () {},
                controller: ScrollController(initialScrollOffset: offset),
                scrollToCurrent: false,
              ),
              const Positioned.fill(
                child: ColoredBox(color: Color(0x8C000000)),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: KartyStepSheet(
                  unit: unit,
                  step: step,
                  scale: scale,
                ),
              ),
            ],
          ),
        );

    await render(
      tester,
      const Size(40 + 430 + 40 + 430 + 40, 932 + 180),
      board([
        (
          'Bitmiş desteye dokununca',
          'Kelimeleri ve ustalıkları',
          withSheet(unit.steps[1], 0),
        ),
        (
          'Sıradaki desteye dokununca',
          'Ne zaman açılacağı, ne geleceği',
          withSheet(unit.steps[3], 260 * scale),
        ),
      ]),
      'goldens/karty_path_sheets.png',
    );
  });
}

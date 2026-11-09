import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';

import 'helpers/karty_path_preview.dart';
import 'helpers/preview_fonts.dart';

/// Pekiştirme halkası: yol kapıya girip onu dolaşır.
///
///   flutter test --update-goldens test/karty_path_gate_preview_test.dart
///
/// İki pano: bugünkü içerik (ünite 16 kelime, desteler bitmiş, yalnız
/// tekrar) ve içerik artınca (ünite 40 kelime; halkada 40 taş).
void main() {
  setUpAll(loadPreviewFonts);

  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyPathData today() => KartyPathData(
        units: [
          KartyUnit(
            number: 1,
            title: 'Evde',
            state: KartyUnitState.current,
            wordCount: 16,
            consolidatedCount: 9,
            emblem: img('haus'),
            steps: const [
              KartyStep(
                  state: KartyStepState.done,
                  deck: 1,
                  label: 'Deste 1',
                  newGoal: 8),
              KartyStep(
                  state: KartyStepState.done,
                  deck: 2,
                  label: 'Deste 2',
                  newGoal: 8),
              KartyStep(
                  state: KartyStepState.current,
                  label: 'Tekrar',
                  newGoal: 0,
                  reviewCount: 7),
            ],
          ),
          KartyUnit(
            number: 2,
            title: 'Yolculuk',
            state: KartyUnitState.locked,
            wordCount: 16,
            emblem: img('koffer'),
            unlockHint: "Evde'nin %80'i pekişince açılır",
            steps: const [
              KartyStep(state: KartyStepState.locked, deck: 1),
              KartyStep(state: KartyStepState.locked, deck: 2),
            ],
          ),
        ],
      );

  KartyPathData later() => KartyPathData(
        units: [
          KartyUnit(
            number: 1,
            title: 'Evde',
            state: KartyUnitState.current,
            wordCount: 40,
            consolidatedCount: 30,
            emblem: img('haus'),
            steps: const [
              KartyStep(
                  state: KartyStepState.done,
                  deck: 1,
                  label: 'Deste 1',
                  newGoal: 8),
              KartyStep(
                  state: KartyStepState.done,
                  deck: 2,
                  label: 'Deste 2',
                  newGoal: 8),
              KartyStep(
                  state: KartyStepState.done,
                  deck: 3,
                  label: 'Deste 3',
                  newGoal: 8),
              KartyStep(
                  state: KartyStepState.done,
                  deck: 4,
                  label: 'Deste 4',
                  newGoal: 8),
              KartyStep(
                  state: KartyStepState.done,
                  deck: 5,
                  label: 'Deste 5',
                  newGoal: 8),
              KartyStep(
                  state: KartyStepState.current,
                  label: 'Tekrar',
                  newGoal: 0,
                  reviewCount: 15),
            ],
          ),
          KartyUnit(
            number: 2,
            title: 'Yolculuk',
            state: KartyUnitState.locked,
            wordCount: 40,
            emblem: img('koffer'),
            unlockHint: "Evde'nin %80'i pekişince açılır",
            steps: const [
              KartyStep(state: KartyStepState.locked, deck: 1),
              KartyStep(state: KartyStepState.locked, deck: 2),
            ],
          ),
        ],
      );

  Widget phone(KartyPathData data,
          {required double height, double offset = 0}) =>
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
            child: KartyPathScreen(
              data: data,
              header: previewPathHeader,
              stations: previewStations(),
              onContinue: () {},
              scrollToCurrent: false,
            ),
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

  testWidgets('pekiştirme halkası', (tester) async {
    const height = 1400.0;
    const size = Size(1020, height + 180);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: board([
          (
            'Bugün',
            'Ünite 16 kelime · 9 pekişti',
            phone(today(), height: height)
          ),
          (
            'İçerik artınca',
            'Ünite 40 kelime · 30 pekişti',
            phone(later(), height: height)
          ),
        ]),
      ),
    );
    await tester.pump();
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/karty_path_gate.png'),
    );
  });
}

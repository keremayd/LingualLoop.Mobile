import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';

import 'helpers/karty_path_preview.dart';
import 'helpers/preview_fonts.dart';

/// Ünite açılışından sonra patikaya geliş: kamera açılan üniteye vardıktan
/// sonraki kareler (örnek veri, örnek ünite adları).
///
///   flutter test --update-goldens test/karty_path_arrival_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyPathData sample() => KartyPathData(
        units: [
          KartyUnit(
            number: 1,
            title: 'Evde',
            state: KartyUnitState.done,
            wordCount: 16,
            consolidatedCount: 13,
            emblem: img('haus'),
            steps: const [
              KartyStep(
                state: KartyStepState.done,
                deck: 1,
                label: 'Deste 1',
                title: 'Deste 1',
                newCount: 8,
              ),
              KartyStep(
                state: KartyStepState.done,
                deck: 2,
                label: 'Deste 2',
                title: 'Deste 2',
                newCount: 8,
              ),
            ],
          ),
          KartyUnit(
            number: 2,
            title: 'Yolculuk',
            state: KartyUnitState.current,
            wordCount: 12,
            emblem: img('koffer'),
            unlockHint: "Ünite 1'in %80'i pekişince açılır",
            steps: const [
              KartyStep(
                state: KartyStepState.current,
                deck: 1,
                label: 'Deste 1',
                title: 'Deste 1',
                reviewCount: 4,
              ),
              KartyStep(
                state: KartyStepState.upcoming,
                deck: 2,
                label: 'Deste 2',
                title: 'Deste 2',
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
            unlockHint: "Ünite 2'nin %80'i pekişince açılır",
            steps: const [
              KartyStep(state: KartyStepState.locked),
              KartyStep(state: KartyStepState.locked),
            ],
          ),
        ],
      );

  Widget phone(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: SizedBox(
          width: 430,
          height: 932,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(430, 932),
              padding: EdgeInsets.only(top: 47, bottom: 34),
              devicePixelRatio: 2,
            ),
            child: child,
          ),
        ),
      );

  testWidgets('patikaya geliş — kareler', (tester) async {
    const k = 0.5;
    const frames = [
      (0.00, 'Kamera varır', 'Ünite kilitli, kapı açılmadı'),
      (0.10, 'Kapı açılır', 'Onaya dönüp zıplar'),
      (0.24, 'Fitil iner', 'Taşlar sırayla yanar'),
      (0.42, 'Kilit açılır', 'Kanca kalkar'),
      (0.56, 'Renk yayılır', 'Kilit düşer, nesne zıplar'),
      (0.80, 'Düğümler açılır', 'Fitil vardıkça'),
      (1.00, 'Son hâl', 'Şu anki destenin balonu'),
    ];
    final data = sample();
    const size = Size(40 + 7 * 430 * k + 6 * 24 + 40, 34 + 84 + 932 * k + 40);

    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: const Color(0xFF020A18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 34, 40, 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, (t, title, subtitle)) in frames.indexed) ...[
                  if (i > 0) const SizedBox(width: 24),
                  Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: AppTypography.heading,
                          fontFamily: AppTypography.displayFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF8FA0B5),
                          fontSize: 15,
                          fontWeight: AppTypography.body,
                          fontFamily: AppTypography.family,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 430 * k,
                        height: 932 * k,
                        child: FittedBox(
                          child: phone(
                            KartyPathScreen(
                              data: data,
                              header: previewPathHeader,
                              stations: previewStations(),
                              onContinue: () {},
                              scrollToCurrent: false,
                              arrivalUnit: 2,
                              arrivalPreview: t,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/karty_path_arrival.png'),
    );
  });
}

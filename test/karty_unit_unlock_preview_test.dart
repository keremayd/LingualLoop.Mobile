import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/screens/karty_unit_unlock_screen.dart';

import 'helpers/preview_fonts.dart';

/// Ünite açılış kutlamasının önizlemesi (örnek veri, örnek ünite adları).
///
///   flutter test --update-goldens test/karty_unit_unlock_preview_test.dart
///
/// İki pano: giriş animasyonundan altı kare ve tam boy son hâl.
void main() {
  setUpAll(loadPreviewFonts);

  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyUnitUnlock sample() => KartyUnitUnlock(
        completed: KartyUnit(
          number: 1,
          title: 'Evde',
          state: KartyUnitState.done,
          wordCount: 16,
          consolidatedCount: 13,
          emblem: img('haus'),
        ),
        unlocked: KartyUnit(
          number: 2,
          title: 'Yolculuk',
          state: KartyUnitState.current,
          wordCount: 12,
          emblem: img('koffer'),
        ),
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

  Widget board(List<(String, String, Widget)> frames, {double gap = 40}) =>
      Material(
        color: const Color(0xFF020A18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 34, 40, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (title, subtitle, frame)) in frames.indexed) ...[
                if (i > 0) SizedBox(width: gap),
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

  testWidgets('ünite açılışı — kareler', (tester) async {
    const k = 0.5;
    const frames = [
      (0.10, 'Kilitli gelir', 'Patikadaki hâliyle'),
      (0.30, 'Kilit sallanır', 'Açılmadan önce bekleyiş'),
      (0.47, 'Kanca kalkar', 'Kilit açıldı'),
      (0.58, 'Renk yayılır', 'Kilit düşer, nesne zıplar'),
      (0.72, 'Işık açılır', 'Metin gelir'),
      (1.00, 'Son hâl', 'DEVAM ET açılır'),
    ];
    final unlock = sample();

    await render(
      tester,
      const Size(40 + 6 * 430 * k + 5 * 24 + 40, 34 + 84 + 932 * k + 40),
      board(gap: 24, [
        for (final (t, title, subtitle) in frames)
          (
            title,
            subtitle,
            SizedBox(
              width: 430 * k,
              height: 932 * k,
              child: FittedBox(
                child: phone(
                  KartyUnitUnlockScene(
                    unlock: unlock,
                    progress: t,
                    onContinue: () {},
                  ),
                ),
              ),
            ),
          ),
      ]),
      'goldens/karty_unit_unlock_frames.png',
    );
  });

  testWidgets('ünite açılışı — son hâl', (tester) async {
    await render(
      tester,
      const Size(40 + 430 + 40, 34 + 84 + 932 + 40),
      board([
        (
          'Ünite açıldı',
          'Oyundan dönünce, patikadan önce',
          phone(
            KartyUnitUnlockScene(
              unlock: sample(),
              progress: 1,
              onContinue: () {},
            ),
          ),
        ),
      ]),
      'goldens/karty_unit_unlock.png',
    );
  });
}

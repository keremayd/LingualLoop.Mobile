import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/models/karty_session_summary.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/screens/karty_session_summary_screen.dart';

import 'helpers/preview_fonts.dart';

/// Karty oyun özetinin ("Deste tamam!") önizlemesi — örnek veri.
///
///   flutter test --update-goldens test/karty_session_summary_preview_test.dart
///
/// İki pano: giriş animasyonundan altı kare ve dört durumun tam boy son hâli
/// (sıradan deste, ilk deste, yalnız tekrar, pratik).
void main() {
  setUpAll(loadPreviewFonts);

  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyWord word(String file, String text, String article) =>
      KartyWord(word: text, article: article, image: img(file), box: 1);

  KartyUnit unit(int consolidated) => KartyUnit(
        number: 1,
        title: 'Evde',
        state: KartyUnitState.current,
        wordCount: 16,
        consolidatedCount: consolidated,
        emblem: img('haus'),
      );

  // Sıradan deste: önceki destenin kelimeleri tekrarda pekişti, lige yakın.
  final ordinary = KartySessionSummary(
    unit: unit(8),
    deck: 2,
    consolidatedBefore: 3,
    newCount: 8,
    reviewCount: 6,
    points: 18,
    correct: 20,
    answered: 22,
    revenge: 2,
    league: const KartyLeagueNote(
      nextLeagueKey: 'supernova',
      nextLeagueName: 'Supernova',
      pointsLeft: 2,
    ),
    words: [
      word('apfel', 'Apfel', 'der'),
      word('banane', 'Banane', 'die'),
      word('brot', 'Brot', 'das'),
      word('buch', 'Buch', 'das'),
      word('katze', 'Katze', 'die'),
      word('lampe', 'Lampe', 'die'),
      word('schluessel', 'Schlüssel', 'der'),
      word('staubsauger', 'Staubsauger', 'der'),
    ],
  );

  // İlk deste: yeni kelimeler aynı gün pekişmez, çubuk yerinde kalır. En
  // uzun hâl: iki satırlık alt satır ve lig satırı birlikte.
  final firstDay = KartySessionSummary(
    unit: unit(0),
    deck: 1,
    consolidatedBefore: 0,
    newCount: 8,
    reviewCount: 0,
    points: 16,
    correct: 16,
    answered: 16,
    revenge: 0,
    league: const KartyLeagueNote(
      nextLeagueKey: 'aytasi',
      nextLeagueName: 'Aytaşı',
      pointsLeft: 4,
    ),
    words: [
      word('stuhl', 'Stuhl', 'der'),
      word('tasche', 'Tasche', 'die'),
      word('wolke', 'Wolke', 'die'),
      word('insel', 'Insel', 'die'),
      word('klosett', 'Klosett', 'das'),
      word('koffer', 'Koffer', 'der'),
      word('lampe', 'Lampe', 'die'),
      word('apfel', 'Apfel', 'der'),
    ],
  );

  // Yalnız tekrar: desteler bitti (sıradaki ünite kilitli), on bir tekrar.
  final reviewDay = KartySessionSummary(
    unit: unit(12),
    consolidatedBefore: 9,
    newCount: 0,
    reviewCount: 11,
    points: 9,
    correct: 9,
    answered: 11,
    revenge: 2,
    words: [
      word('apfel', 'Apfel', 'der'),
      word('banane', 'Banane', 'die'),
      word('brot', 'Brot', 'das'),
      word('buch', 'Buch', 'das'),
      word('katze', 'Katze', 'die'),
      word('lampe', 'Lampe', 'die'),
      word('schluessel', 'Schlüssel', 'der'),
      word('stuhl', 'Stuhl', 'der'),
      word('tasche', 'Tasche', 'die'),
      word('wolke', 'Wolke', 'die'),
      word('insel', 'Insel', 'die'),
    ],
  );

  // Pratik: vakti gelmiş tekrar yok; on soruluk tur, yedi farklı kelime.
  final practiceRound = KartySessionSummary(
    unit: unit(3),
    practice: true,
    consolidatedBefore: 3,
    newCount: 0,
    reviewCount: 0,
    points: 8,
    correct: 8,
    answered: 10,
    revenge: 2,
    words: [
      word('apfel', 'Apfel', 'der'),
      word('banane', 'Banane', 'die'),
      word('brot', 'Brot', 'das'),
      word('katze', 'Katze', 'die'),
      word('lampe', 'Lampe', 'die'),
      word('stuhl', 'Stuhl', 'der'),
      word('wolke', 'Wolke', 'die'),
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

  testWidgets('oturum özeti — kareler', (tester) async {
    const k = 0.5;
    const frames = [
      (0.14, 'Başlık', 'Karolar silüet olarak gelir'),
      (0.30, 'Kelimeler açılır', 'Silüet sırayla renge döner'),
      (0.48, 'Son kelimeler', 'Adları artikel rengiyle'),
      (0.66, 'Ünite kartı', 'Çubuk dolmaya başlar'),
      (0.80, 'Sayılar', "Çubuk 3'ten 8'e, puan sayar"),
      (1.00, 'Son hâl', 'Düğmeler açılır'),
    ];

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
                  KartySessionSummaryScene(
                    summary: ordinary,
                    progress: t,
                    onContinue: () {},
                    onPractice: () {},
                  ),
                ),
              ),
            ),
          ),
      ]),
      'goldens/karty_session_summary_frames.png',
    );
  });

  testWidgets('oturum özeti — dört durum', (tester) async {
    Widget scene(KartySessionSummary summary) => phone(
          KartySessionSummaryScene(
            summary: summary,
            progress: 1,
            onContinue: () {},
            onPractice: () {},
          ),
        );

    await render(
      tester,
      const Size(40 + 4 * 430 + 3 * 40 + 40, 34 + 84 + 932 + 40),
      board([
        (
          'Sıradan deste',
          'Önceki destenin kelimeleri pekişti',
          scene(ordinary)
        ),
        ('İlk deste', 'En uzun hâl: iki satır + lig satırı', scene(firstDay)),
        (
          'Yalnız tekrar',
          'Desteler bitti; 8\'den fazlası "+N"',
          scene(reviewDay)
        ),
        (
          'Pratik',
          'On soruluk tur; çubuk kıpırdamaz',
          scene(practiceRound)
        ),
      ]),
      'goldens/karty_session_summary.png',
    );
  });
}

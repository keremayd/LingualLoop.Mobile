import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';
import 'package:lingualloop/ui/widgets/app_bottom_nav_bar.dart';
import 'package:lingualloop/ui/widgets/streak_day_card.dart';
import 'package:lingualloop/ui/widgets/streak_day_scenes.dart';
import 'package:lingualloop/ui/widgets/streak_week_strip.dart';

import 'helpers/karty_path_preview.dart';
import 'helpers/preview_fonts.dart';

/// Birleşik ana ekran önerisi: ana ekran Karty Yolu'nun kendisi; Artikel
/// Pusulası ve Rövanş şu anki destenin iki yanında yan durak. Üç durum,
/// gerçek cihaz boyutunda ve açılıştaki kaydırmayla; dördüncü kare üst
/// şeritteki aleve dokununca açılan seri penceresi.
///
///   flutter test --update-goldens test/home_path_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  ImageProvider img(String name) => MemoryImage(
        File('test/fixtures/karty_words/$name.png').readAsBytesSync(),
      );

  KartyUnit lockedUnit(int words) => KartyUnit(
        number: 2,
        title: 'Yolculuk',
        state: KartyUnitState.locked,
        wordCount: words,
        emblem: img('koffer'),
        unlockHint: "Evde'nin %80'i pekişince açılır",
        steps: [
          for (var i = 1; i <= (words / 8).ceil(); i++)
            KartyStep(state: KartyStepState.locked, deck: i),
        ],
      );

  // 1 — İlk gün: ilk deste, duraklar henüz kapalı.
  final firstDay = KartyPathData(
    units: [
      KartyUnit(
        number: 1,
        title: 'Evde',
        state: KartyUnitState.current,
        wordCount: 16,
        emblem: img('haus'),
        steps: const [
          KartyStep(
            state: KartyStepState.current,
            deck: 1,
            label: 'Deste 1',
          ),
          KartyStep(state: KartyStepState.upcoming, deck: 2, label: 'Deste 2'),
        ],
      ),
      lockedUnit(16),
    ],
  );

  // 2 — Ünitenin ortası: ikinci deste yarıda, tekrarlar karışık.
  final midUnit = KartyPathData(
    units: [
      KartyUnit(
        number: 1,
        title: 'Evde',
        state: KartyUnitState.current,
        wordCount: 24,
        consolidatedCount: 5,
        emblem: img('haus'),
        steps: const [
          KartyStep(
            state: KartyStepState.done,
            deck: 1,
            label: 'Deste 1',
            dueCount: 2,
          ),
          KartyStep(
            state: KartyStepState.current,
            deck: 2,
            label: 'Deste 2',
            newCount: 3,
            reviewCount: 5,
          ),
          KartyStep(state: KartyStepState.upcoming, deck: 3, label: 'Deste 3'),
        ],
      ),
      lockedUnit(16),
    ],
  );

  // 3 — Ünite sonu: desteler bitti, kapı kapalı; şu anki adım tekrar.
  final unitEnd = KartyPathData(
    units: [
      KartyUnit(
        number: 1,
        title: 'Evde',
        state: KartyUnitState.current,
        wordCount: 16,
        consolidatedCount: 9,
        emblem: img('haus'),
        steps: const [
          KartyStep(state: KartyStepState.done, deck: 1, label: 'Deste 1'),
          KartyStep(state: KartyStepState.done, deck: 2, label: 'Deste 2'),
          KartyStep(
            state: KartyStepState.current,
            label: 'Tekrar',
            newGoal: 0,
            reviewCount: 7,
          ),
        ],
      ),
      lockedUnit(16),
    ],
  );

  Widget phone(
    KartyPathData data, {
    required KartyPathStations stations,
    required int streak,
    required bool playedToday,
    required int rank,
    required int tickets,
    Widget? overlay,
  }) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: SizedBox(
          width: 430,
          height: 932,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(430, 932),
              padding: EdgeInsets.only(top: 47, bottom: 34),
              devicePixelRatio: 2,
              disableAnimations: true,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Scaffold(
                    backgroundColor: const Color(0xFF041227),
                    body: SafeArea(
                      bottom: false,
                      child: KartyPathScreen(
                        data: data,
                        onContinue: () {},
                        stations: stations,
                        header: (scale) => previewPathHeader(
                          scale,
                          streak: streak,
                          playedToday: playedToday,
                          rank: rank,
                          tickets: tickets,
                        ),
                      ),
                    ),
                    bottomNavigationBar:
                        AppBottomNavBar(selectedIndex: 0, onTap: (_) {}),
                  ),
                ),
                if (overlay != null) Positioned.fill(child: overlay),
              ],
            ),
          ),
        ),
      );

  /// Alevine dokununca alttan açılan seri penceresi: ana ekrandaki seri
  /// kartının kendisi, sahnesi ve hafta şeridiyle.
  Widget streakSheet({required int days, required bool playedToday}) {
    const scale = 430 / 750;
    final now = DateTime(2026, 11, 5);
    final scene =
        StreakScene.byKey(playedToday ? 'gunluk_seri' : 'gunluk_seri_bekliyor');
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 430,
          padding: const EdgeInsets.fromLTRB(
              40 * scale, 22 * scale, 40 * scale, 34 + 40 * scale),
          decoration: const BoxDecoration(
            color: Color(0xFF041227),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80 * scale,
                height: 10 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF163258),
                  borderRadius: BorderRadius.circular(5 * scale),
                ),
              ),
              SizedBox(height: 30 * scale),
              StreakDayCard(
                scale: scale,
                days: days,
                message: scene.message,
                sceneAsset: scene.asset,
                sceneAspect: scene.aspect,
                cardColor: scene.cardColor,
                sceneEdgeColor: scene.sceneEdgeColor,
                faceOpacity: scene.faceOpacity,
                sceneZoom: scene.zoom,
                sceneAnchorY: scene.anchorY,
                sceneFadeEnd: scene.fadeEnd,
                playedToday: playedToday,
                week: [
                  for (var i = 6; i >= 0; i--)
                    StreakDay(
                      date: now.subtract(Duration(days: i)),
                      active: i > 0 && i < days + 1,
                      frozen: false,
                      isToday: i == 0,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  void open() {}

  testWidgets('birleşik ana ekran — üç durum', (tester) async {
    const size = Size(40 + 4 * 430 + 3 * 40 + 40, 34 + 90 + 932 + 40);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: board([
          (
            'İlk gün',
            'Duraklar ilk kelimelerle açılır',
            phone(
              firstDay,
              streak: 0,
              playedToday: false,
              rank: 4,
              tickets: 15,
              stations: KartyPathStations(
                article: previewArticleStation(detail: '2 kelime öğren'),
                review: previewReviewStation(detail: 'Hatan yok'),
              ),
            ),
          ),
          (
            'Ünitenin ortası',
            'Deste yarıda; Artikel ve Rövanş açık',
            phone(
              midUnit,
              streak: 4,
              playedToday: true,
              rank: 2,
              tickets: 12,
              stations: KartyPathStations(
                article: previewArticleStation(
                  detail: '6 kart',
                  onTap: open,
                ),
                review: previewReviewStation(detail: '2 kart', onTap: open),
              ),
            ),
          ),
          (
            'Ünite sonu',
            'Desteler bitti, kapı için tekrar',
            phone(
              unitEnd,
              streak: 2,
              playedToday: false,
              rank: 1,
              tickets: 9,
              stations: KartyPathStations(
                article: previewArticleStation(
                  detail: '16 kart',
                  onTap: open,
                ),
                review: previewReviewStation(detail: '1 kart', onTap: open),
              ),
            ),
          ),
          (
            'Seri',
            'Üst şeritteki aleve dokununca',
            phone(
              unitEnd,
              streak: 2,
              playedToday: false,
              rank: 1,
              tickets: 9,
              stations: KartyPathStations(
                article: previewArticleStation(
                  detail: '16 kart',
                  onTap: open,
                ),
                review: previewReviewStation(detail: '1 kart', onTap: open),
              ),
              overlay: streakSheet(days: 2, playedToday: false),
            ),
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
      matchesGoldenFile('goldens/home_path.png'),
    );
  });
}

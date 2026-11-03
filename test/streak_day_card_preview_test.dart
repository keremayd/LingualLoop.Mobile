import 'helpers/preview_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/streak_day_card.dart';
import 'package:lingualloop/ui/widgets/streak_day_scenes.dart';
import 'package:lingualloop/ui/widgets/streak_week_strip.dart';

/// Güne özel seri kartları — kayıtlı bütün sahneler.
///
/// **Gerçek cihaz genişliğinde** çiziliyor (430px iPhone), çünkü karar
/// verilecek şey oranlar değil okunabilirlik: sahnenin sol kenarı karta
/// eriyor mu, metin sahneye giriyor mu, şerit sıkışıyor mu.
///
///   flutter test --update-goldens test/streak_day_card_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('gun 100 karti', (tester) async {
    const size = Size(430, 2080);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    // Ana ekranla aynı ölçek: 430 genişlik, 40 birim yatay dolgu.
    const scale = 430 / 750;
    final now = DateTime(2026, 8, 20); // Perşembe
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF041227),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // (anahtar, gün, bugün oynandı mı)
                for (final entry in const [
                  ('gun_100', 100, true),
                  ('ritmi_koru', 14, true),
                  ('harika_gidiyorsun', 21, true),
                  // Sönük alev: seri var ama bugün henüz oynanmamış.
                  ('hedefe_dogru', 6, false),
                  ('madalyani_kazan', 15, true),
                  ('ruzgari_yakala', 12, true),
                  ('istikrar_guclendirir', 3, true),
                  ('kendi_rekorun', 23, true),
                  ('serin_korundu', 8, false),
                  ('gunluk_seri_bekliyor', 2, false),
                  ('beyni_esnet', 0, false),
                  ('seni_ozledik', 0, false),
                ]) ...[
                  Builder(builder: (context) {
                    final scene = StreakScene.byKey(entry.$1);
                    return StreakDayCard(
                      scale: scale,
                      days: entry.$2,
                      message: scene.message,
                      sceneAsset: scene.asset,
                      sceneAspect: scene.aspect,
                      cardColor: scene.cardColor,
                      sceneEdgeColor: scene.sceneEdgeColor,
                      faceOpacity: scene.faceOpacity,
                      sceneZoom: scene.zoom,
                      sceneAnchorY: scene.anchorY,
                      sceneFadeEnd: scene.fadeEnd,
                      playedToday: entry.$3,
                      week: [
                        for (var i = 6; i >= 0; i--)
                          StreakDay(
                            date: now.subtract(Duration(days: i)),
                            active: i != 0 && i != 3,
                            // Perşembe korumayla tamamlanmış: ana kart bunu
                            // normal beyaz tikten ayrı göstermeli.
                            frozen: i == 3,
                            isToday: i == 0,
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/streak_day_card.png'),
    );
  });

  testWidgets('ilk gün, normal gün ve rekor aynı görselli düzeni kullanır',
      (tester) async {
    const size = Size(430, 510);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    final today = DateTime(2026, 10, 12);

    Widget card(int days, int longest) {
      final scene = StreakScene.resolve(StreakSceneContext(
        streak: days,
        playedToday: true,
        hasEverStreaked: true,
        freezeUsedRecently: false,
        isAtPersonalBest: days > 1 && days == longest,
      ));
      return StreakDayCard(
        scale: 430 / 750,
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
        week: [
          for (var i = 6; i >= 0; i--)
            StreakDay(
              date: today.subtract(Duration(days: i)),
              active: i < days,
              frozen: false,
              isToday: i == 0,
            ),
        ],
        playedToday: true,
      );
    }

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF041227),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              card(1, 1),
              const SizedBox(height: 24),
              card(4, 8),
              const SizedBox(height: 24),
              card(4, 4),
            ],
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/streak_day_card_daily.png'),
    );
  });
}

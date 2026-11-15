import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/home_top_bar.dart';

import 'helpers/preview_fonts.dart';

/// Ana ekranın üst şeridi: solda seri, sağda bilet (16 Kas 2026'dan beri;
/// lig ve koruma şeritten kalktı).
///
///   flutter test --update-goldens test/home_top_bar_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('ust serit', (tester) async {
    const size = Size(750, 300);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF041227),
          body: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeTopBar(
                    scale: 1,
                    streakDays: 4,
                    playedToday: true,
                    tickets: 15,
                  ),
                  SizedBox(height: 40),
                  // Bugün oynanmadı: alev beyaz siluet, %55.
                  HomeTopBar(
                    scale: 1,
                    streakDays: 0,
                    playedToday: false,
                    tickets: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await precachePreviewImages(tester);

    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/home_top_bar.png'),
    );
  });

  testWidgets('ust serit - gercek cihaz genisligi', (tester) async {
    // 430 pikselde ve 3x yoğunlukta çizer: üstteki önizlemede tasarım birimi
    // = piksel olduğu için boyuta göre sadeleşen çizimler orada cihazdaki
    // hâliyle görünmez. (Koruma ikonu bu yüzden golden'da doğru, cihazda
    // okunmaz çıkmıştı; ikon 16 Kas 2026'da şeritten kalktı.)
    const size = Size(430, 200);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = const Size(1290, 600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF041227),
          body: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: HomeTopBar(
                scale: 430 / 750,
                streakDays: 4,
                playedToday: true,
                tickets: 15,
              ),
            ),
          ),
        ),
      ),
    );
    await precachePreviewImages(tester);

    await expectLater(
      find.byType(HomeTopBar),
      matchesGoldenFile('goldens/home_top_bar_device.png'),
    );
  });
}

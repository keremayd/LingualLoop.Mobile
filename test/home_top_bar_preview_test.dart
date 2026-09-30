import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/home_top_bar.dart';

/// Ana ekranın üst şeridi: lig · bilet · seviye · koruma.
///
///   flutter test --update-goldens test/home_top_bar_preview_test.dart
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Inter');
    final bytes = File(
      '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile'
      '/assets/fonts/Inter-SemiBold.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  testWidgets('ust serit', (tester) async {
    const size = Size(750, 300);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

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
                    leagueKey: 'kosmoz',
                    leagueRank: 1,
                    tickets: 15,
                    level: 2,
                    freezeCount: 2,
                  ),
                  SizedBox(height: 40),
                  // Sıralama verisi yoksa rozet sayısız çizilir.
                  HomeTopBar(
                    scale: 1,
                    leagueKey: 'supernova',
                    leagueRank: null,
                    tickets: 8,
                    level: 4,
                    freezeCount: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // PNG ikonlar ilk frame'de henüz decode edilmemiş olabilir; golden
    // yalnızca sayıları değil gerçek topbarı doğrulamalı.
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/home_top_bar.png'),
    );
  });

  testWidgets('ust serit - gercek cihaz genisligi', (tester) async {
    // **Bu test 430 pikselde çiziyor ve bu tesadüf değil.** Üstteki önizleme
    // 750 piksellik tuval kuruyor, yani tasarım birimi = piksel. Boyuta göre
    // davranış değiştiren bir çizim (örn. `StreakFreezeFlake`, 46 px altında
    // sadeleşiyor) orada **gerçek cihazdaki hâlini göstermiyor**: 70 birimlik
    // ikon 750'lik tuvalde 70 px, 430'luk cihazda 40 px.
    //
    // Buz ikonu tam bu yüzden golden'da doğru, cihazda okunmaz çıktı.
    // §4.4'teki "golden tek kareye bakar" uyarısının kardeşi: **golden farklı
    // boyutta da çizebilir.**
    const size = Size(430, 200);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = const Size(1290, 600);
    // Cihazın gerçek yoğunluğu: 3x. 1x çizilseydi ikonun bu boyutta
    // okunup okunmadığı görülemezdi.
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
                leagueKey: 'yildiz',
                leagueRank: 1,
                tickets: 15,
                level: 2,
                freezeCount: 2,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(HomeTopBar),
      matchesGoldenFile('goldens/home_top_bar_device.png'),
    );
  });
}

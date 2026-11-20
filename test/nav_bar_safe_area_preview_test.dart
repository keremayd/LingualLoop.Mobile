import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/ui/app_typography.dart';
import 'package:stelinda/ui/widgets/app_bottom_nav_bar.dart';

import 'helpers/preview_fonts.dart';

/// Alt menünün altı, ekranın yuvarlak köşesi ve ana ekran çizgisiyle
/// (iPhone 17, 402 pt). Alt boşluk = max(12 birim, alt güvenli alan − 20):
/// üç hâl aynı widget'ın farklı güvenli alanla çizimi — 26,4 → 6 pt (önce),
/// 54 → 34 pt (güvenli alanın tamamı), 34 → 14 pt (şimdi).
///
///   flutter test --update-goldens test/nav_bar_safe_area_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  const width = 402.0;
  const window = 170.0;

  Widget bottomOfScreen(String title, double inset) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontFamily: AppTypography.family,
                fontWeight: AppTypography.label,
                fontSize: 15,
              ),
            ),
          ),
          // Ekranın alt köşeleri: iPhone'un ekranı ~62 pt yuvarlak.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(62),
            ),
            child: SizedBox(
              width: width,
              height: window,
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(width, 874),
                  padding: EdgeInsets.only(bottom: inset),
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0xFF041227)),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AppBottomNavBar(selectedIndex: 0, onTap: (_) {}),
                    ),
                    // Ana ekran çizgisi: 134 × 5 pt, alttan 8 pt.
                    Positioned(
                      left: (width - 134) / 2,
                      bottom: 8,
                      child: Container(
                        width: 134,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  testWidgets('alt menü: önce, güvenli alanın tamamı, şimdi', (tester) async {
    const size = Size(width + 40, 3 * (window + 46) + 20);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                bottomOfScreen(
                    'Önce: alt boşluk 6 pt, karo köşede kesiliyor', 26.4),
                bottomOfScreen(
                    'Dün: güvenli alanın tamamı (34 pt), menü 28 pt uzadı', 54),
                bottomOfScreen(
                    'Şimdi: 14 pt, karo sığıyor, menü 8 pt uzun', 34),
              ],
            ),
          ),
        ),
      ),
    );
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/nav_bar_safe_area.png'),
    );
  });
}

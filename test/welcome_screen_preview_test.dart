import 'helpers/preview_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/screens/welcome_screen.dart';

/// Hoş geldin ekranı — **gerçek cihaz ölçüsünde** (430×932).
///
///   flutter test --update-goldens test/welcome_screen_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('hos geldin ekrani', (tester) async {
    const size = Size(430, 932);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    ));
    await tester.pump(const Duration(milliseconds: 40));

    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pump();

    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/welcome_screen.png'));
  });
}

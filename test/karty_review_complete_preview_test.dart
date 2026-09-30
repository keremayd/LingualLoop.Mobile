import 'helpers/preview_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/karty_review_complete_state.dart';

/// Rövanş tamamlanma ekranını gerçek iPhone boyutunda görsel olarak doğrular.
///
///   flutter test --update-goldens test/karty_review_complete_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('rovanş tamamlanma sahnesi', (tester) async {
    const size = Size(430, 932);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF041227),
          body: KartyReviewCompleteState(
            scale: size.width / 750,
            rewardTickets: 1,
            onClose: () {},
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/karty_review_complete_screen.png'),
    );
  });
}

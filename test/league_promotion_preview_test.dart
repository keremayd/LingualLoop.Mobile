import 'helpers/preview_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/responses/LeagueProgressResponse.dart';
import 'package:lingualloop/ui/screens/league_promotion_screen.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('lig terfi ekranı', (tester) async {
    const size = Size(430, 932);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LeaguePromotionScreen(
          promotion: const LeaguePromotionResponse(
            fromRank: 8,
            fromLeagueKey: 'nebula',
            fromLeagueName: 'Nebula',
            toRank: 9,
            toLeagueKey: 'kosmoz',
            toLeagueName: 'Kosmoz',
          ),
          onContinue: () async => true,
        ),
      ),
    );

    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/league_promotion_screen.png'),
    );
  });

  testWidgets('geçiş boyunca hata vermez ve devam butonunu kilitler',
      (tester) async {
    const size = Size(430, 932);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: LeaguePromotionScreen(
          promotion: const LeaguePromotionResponse(
            fromRank: 8,
            fromLeagueKey: 'nebula',
            fromLeagueName: 'Nebula',
            toRank: 9,
            toLeagueKey: 'kosmoz',
            toLeagueName: 'Kosmoz',
          ),
          onContinue: () async => true,
        ),
      ),
    );

    const continueKey = Key('league-promotion-continue');
    await tester.pump(const Duration(milliseconds: 280));
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<DepthPressableButton>(find.byKey(continueKey)).enabled,
      isFalse,
    );

    await tester.pump(const Duration(milliseconds: 2300));
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<DepthPressableButton>(find.byKey(continueKey)).enabled,
      isTrue,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/profile_learning_stats_card.dart';

void main() {
  testWidgets('article learned icon preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 220));
    tester.view.physicalSize = const Size(420, 220);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: Color(0xFF041227),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ArticleLearnedIcon(size: 150),
                ArticleLearnedIcon(size: 86),
                ArticleLearnedIcon(size: 48),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/article_icon.png'),
    );
  });
}

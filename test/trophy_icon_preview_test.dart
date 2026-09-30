import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

void main() {
  testWidgets('trophy icon preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 220));
    tester.view.physicalSize = const Size(400, 220);
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
                TrophyIcon(size: 150),
                TrophyIcon(size: 84),
                TrophyIcon(size: 44),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/trophy_icon.png'),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

void main() {
  testWidgets('check mark preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 180));
    tester.view.physicalSize = const Size(400, 180);
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
                QuestCheckMark(size: 110),
                QuestCheckMark(size: 44),
                QuestCheckMark(size: 28),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/check_mark.png'),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

void main() {
  testWidgets('quest icons preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(760, 260));
    tester.view.physicalSize = const Size(760, 260);
    tester.view.devicePixelRatio = 1.0;

    const keys = [
      'checkin',
      'correct_five',
      'learn_three',
      'review_two',
      'streak_three',
    ];

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF041227),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final k in keys)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C2244),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: QuestIcon(questKey: k, size: 66),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C2244),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: QuestIcon(questKey: k, size: 33),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quest_icons.png'),
    );
  });
}

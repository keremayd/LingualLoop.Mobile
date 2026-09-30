import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/league_badge_mark.dart';

void main() {
  testWidgets('league badge sheet preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1240, 860));
    tester.view.physicalSize = const Size(1240, 860);
    tester.view.devicePixelRatio = 1.0;

    const keys = [
      'merkur',
      'aytasi',
      'yildiz',
      'kuyruklu',
      'mars',
      'uranus',
      'saturn',
      'nebula',
      'kosmoz',
      'supernova',
      'pulsar',
    ];

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF041227),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  children: [
                    for (final k in keys)
                      LeagueBadgeMark(leagueKey: k, size: 150),
                  ],
                ),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 24,
                  children: [
                    for (final k in keys)
                      LeagueBadgeMark(leagueKey: k, size: 44),
                  ],
                ),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 40,
                  children: [
                    LeagueBadgeMark(
                        leagueKey: 'mars', size: 150, locked: true),
                    LeagueBadgeMark(
                        leagueKey: 'mars', size: 88, locked: true),
                    LeagueBadgeMark(
                        leagueKey: 'mars', size: 44, locked: true),
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
      matchesGoldenFile('goldens/league_badges.png'),
    );
  });
}

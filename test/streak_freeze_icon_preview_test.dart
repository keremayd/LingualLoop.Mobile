import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/streak_freeze_flake.dart';

/// Seri koruma ikonu — büyük ve küçük boyutta birlikte (§7/7).
void main() {
  testWidgets('buz ikonu', (tester) async {
    tester.view.physicalSize = const Size(700, 340);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF041227),
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StreakFreezeFlake(size: 190),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreakFreezeFlake(size: 64),
                    SizedBox(height: 20),
                    // Üst şeritteki gerçek boyut.
                    StreakFreezeFlake(size: 40),
                    SizedBox(height: 20),
                    StreakFreezeFlake(size: 25),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/streak_freeze_icon.png'),
    );
  });
}

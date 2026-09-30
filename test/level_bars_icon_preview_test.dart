import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/level_bars_icon.dart';

void main() {
  testWidgets('level bars icon preview', (tester) async {
    const size = Size(420, 200);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0xFF041227),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final s in [128.0, 64.0, 34.0])
                  Container(
                    width: s * 1.5,
                    height: s * 1.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C2244),
                      borderRadius: BorderRadius.circular(s * 0.3),
                    ),
                    alignment: Alignment.center,
                    child: LevelBarsIcon(size: s),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/level_bars_icon.png'),
    );
  });
}

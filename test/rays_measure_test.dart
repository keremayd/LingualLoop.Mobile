import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_reward_celebration.dart';

/// Ölçüm karesi: yalnız ışık dilimleri. Tasarım önizlemesi değil —
/// referans görselle sayısal karşılaştırma için.
void main() {
  testWidgets('isik dilimleri olcum', (tester) async {
    const size = Size(900, 900);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: Color(0xFF041227),
          child: Center(child: LightRaysOnly(box: 900, progress: 0.5)),
        ),
      ),
    );
    await tester.pump();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/rays_measure.png'));
  });
}

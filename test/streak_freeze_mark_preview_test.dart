import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/streak_freeze_mark.dart';

/// Koruma simgesinin (buz bloğu + içinde alev) önizlemesi.
///
///   flutter test --update-goldens test/streak_freeze_mark_preview_test.dart
void main() {
  Widget frame(Widget child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF041227),
        child: Center(child: Padding(padding: const EdgeInsets.all(24), child: child)),
      ),
    );
  }

  testWidgets('buz bloğu — üç boyutta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(880, 420));
    await tester.pumpWidget(frame(
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          StreakFreezeMark(size: 260, animated: false, staticPhase: 0.3),
          SizedBox(width: 50),
          // Gerçek kullanım boyutları: kutlama penceresi ~135pt, karar
          // penceresi ~113pt, çakılmanın sonunda ~29pt.
          StreakFreezeMark(size: 135, animated: false, staticPhase: 0.3),
          SizedBox(width: 40),
          StreakFreezeMark(size: 113, animated: false, staticPhase: 0.3),
          SizedBox(width: 30),
          StreakFreezeMark(size: 29, animated: false, staticPhase: 0.3),
        ],
      ),
    ));
    await tester.pump();

    await expectLater(
      find.byType(Row).first,
      matchesGoldenFile('goldens/freeze_mark_sizes.png'),
    );
  });

  testWidgets('buz bloğu hareket kareleri', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 300));
    await tester.pumpWidget(frame(
      ColoredBox(
        color: const Color(0xFF041227),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            StreakFreezeMark(size: 200, animated: false, staticPhase: 0.0),
            SizedBox(width: 24),
            StreakFreezeMark(size: 200, animated: false, staticPhase: 0.25),
            SizedBox(width: 24),
            StreakFreezeMark(size: 200, animated: false, staticPhase: 0.5),
            SizedBox(width: 24),
            StreakFreezeMark(size: 200, animated: false, staticPhase: 0.75),
          ],
        ),
      ),
    ));
    await tester.pump();

    await expectLater(
      find.byType(ColoredBox).last,
      matchesGoldenFile('goldens/freeze_mark_frames.png'),
    );
  });
}

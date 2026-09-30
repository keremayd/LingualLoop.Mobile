import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/quest_reward_celebration.dart';

/// Kutlamanın filmşeridi. Golden statiktir; hareket ancak kare kare
/// değerlendirilebilir.
void main() {
  const background = Color(0xFF041227);
  const muted = Color(0xFF8FA0B5);

  testWidgets('quest reward celebration filmstrip', (tester) async {
    const frames = [0.10, 0.22, 0.34, 0.50, 0.70, 0.90];
    const cellWidth = 430.0;
    const cellHeight = 800.0;
    const size = Size(cellWidth * 3, cellHeight * 2);

    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: background,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var row = 0; row < 2; row++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var col = 0; col < 3; col++)
                      SizedBox(
                        width: cellWidth,
                        height: cellHeight,
                        // Hüzmeler kutudan taşıyor; gerçek uygulamada bu
                        // istenen şey (tam ekran) ama filmşeritte komşu
                        // kareye karışıyor ve yargıyı bozuyordu.
                        child: ClipRect(
                          child: Stack(
                          children: [
                            // Altta duran görevler ekranını temsilen sade bir
                            // zemin: perdenin ne kadar kapattığı görülsün.
                            Positioned.fill(
                              child: ColoredBox(
                                color: background,
                                child: Center(
                                  child: Container(
                                    width: 360,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B2143),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: QuestRewardCelebration(
                                progress: frames[row * 3 + col],
                                scale: cellWidth / 670,
                                rewardTickets: 3,
                                questTitle: '3 günlük seriye ulaş',
                              ),
                            ),
                            Positioned(
                              left: 10,
                              top: 8,
                              child: Text(
                                't=${frames[row * 3 + col].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    // Golden testlerde Image.asset kendiliğinden çözülmez; bilet görselini
    // elle önden yükletmezsek ödül kadrajda hiç görünmez.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = (element.widget as Image).image;
        await precacheImage(image, element);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quest_reward_celebration.png'),
    );
  });
}

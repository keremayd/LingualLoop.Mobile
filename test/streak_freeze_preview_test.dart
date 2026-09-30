import 'helpers/preview_fonts.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/ui/widgets/Popups/streak_at_risk_popup.dart';
import 'package:lingualloop/ui/widgets/streak_freeze_mark.dart';
import 'package:lingualloop/ui/widgets/streak_week_strip.dart';

/// Seri koruma akışının görsel önizlemesi (gerçek test değil).
///
/// Üretmek için:
///   flutter test --update-goldens test/streak_freeze_preview_test.dart
void main() {
  // Golden'lar varsayılan olarak fontsuz çizer, metinler blok görünür. Metin
  // taşması ve satır sayısı ancak gerçek fontla doğrulanabildiği için Inter
  // burada elle yükleniyor.
  setUpAll(loadPreviewFonts);

  /// Karar anındaki hafta: Pazartesi–Perşembe girildi, **Cuma kaçırıldı**,
  /// Cumartesi de boş, bugün (Pazar) girildi. Kaçırılan günler henüz kurtarılmadı.
  List<DailyActivityDay> weekAtRisk() {
    final today = DateTime(2026, 8, 2);
    const flags = [
      [true, false],
      [true, false],
      [true, false],
      [true, false],
      [true, false],
      [false, false],
      [true, false],
    ];
    return [
      for (var i = 0; i < 7; i++)
        DailyActivityDay(
          date: today.subtract(Duration(days: 6 - i)),
          active: flags[i][0],
          frozen: flags[i][1],
        ),
    ];
  }

  /// Karar sonrası aynı hafta: kaçırılan iki gün korumayla doldu.
  List<DailyActivityDay> weekSaved() {
    return [
      for (final day in weekAtRisk())
        DailyActivityDay(
          date: day.date,
          active: day.active,
          frozen: !day.active,
        ),
    ];
  }

  Widget frame_(Widget child) {
    return MediaQuery(
      data: const MediaQueryData(size: Size(750, 1600)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFF041227),
          child: Center(
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('1 — karar penceresi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(750, 1240));
    await tester.pumpWidget(frame_(
      Padding(
        padding: const EdgeInsets.all(24),
        child: StreakAtRiskCard(
          currentStreak: 12,
          missedDays: 1,
          freezeCount: 2,
          week: weekAtRisk(),
          onResolve: (_) async => null,
          onClose: () {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(StreakAtRiskCard),
      matchesGoldenFile('goldens/streak_1_at_risk.png'),
    );
  });

  testWidgets('2 — aynı kartın sonuç hâli', (tester) async {
    await tester.binding.setSurfaceSize(const Size(750, 1240));
    await tester.pumpWidget(frame_(
      Padding(
        padding: const EdgeInsets.all(24),
        child: StreakAtRiskCard(
          currentStreak: 12,
          missedDays: 1,
          freezeCount: 2,
          week: weekAtRisk(),
          previewResult: DailyActivityResponse(
            currentStreak: 13,
            longestStreak: 13,
            lastActiveDate: '2026-08-03',
            freezeCount: 1,
            streakAtRisk: false,
            missedDays: 1,
            week: weekSaved(),
            checkedInToday: true,
          ),
          onResolve: (_) async => null,
          onClose: () {},
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump(const Duration(milliseconds: 600));

    await expectLater(
      find.byType(StreakAtRiskCard),
      matchesGoldenFile('goldens/streak_2_resolved.png'),
    );
  });

  _loopContinuityTest();

  /// Gün işaretleri iki boyutta: küçükte okunuyor mu, büyükte dağılıyor mu.
  testWidgets('5 — gün işaretleri', (tester) async {
    await tester.binding.setSurfaceSize(const Size(760, 470));
    await tester.pumpWidget(frame_(
      ColoredBox(
        color: const Color(0xFF0C2244),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreakWeekStrip(
                days: [
                  for (var i = 0; i < 3; i++)
                    StreakDay(
                      date: DateTime(2026, 8, 3 - 2 + i),
                      active: i == 0,
                      frozen: i == 1,
                      isToday: false,
                    ),
                ],
                scale: 3.2,
              ),
              const SizedBox(height: 26),
              StreakWeekStrip(
                days: [
                  for (var i = 0; i < 3; i++)
                    StreakDay(
                      date: DateTime(2026, 8, 3 - 2 + i),
                      active: i == 0,
                      frozen: i == 1,
                      isToday: false,
                    ),
                ],
                scale: 0.54,
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();

    await expectLater(
      find.byType(ColoredBox).last,
      matchesGoldenFile('goldens/streak_5_day_marks.png'),
    );
  });

  /// Saplanma animasyonunun kareleri. Hareket tek karede görülemez; döngünün
  /// evreleri (geri çekilme → iniş → çarpma → oturma) yan yana basılır.
  for (final frame in const [
    ('a_geri_cekilme', 0.16),
    ('b_inis', 0.46),
    ('c_carpma', 0.64),
    ('d_oturma', 0.86),
  ]) {
    testWidgets('4 — saplanma: ${frame.$1}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(750, 1240));
      await tester.pumpWidget(frame_(
        Padding(
          padding: const EdgeInsets.all(24),
          child: StreakAtRiskCard(
            currentStreak: 12,
            missedDays: 1,
            freezeCount: 2,
            week: weekAtRisk(),
            strikeProgress: frame.$2,
            strikeTargetIndex: 5,
            onResolve: (_) async => null,
            onClose: () {},
          ),
        ),
      ));
      // Hedef konumu yerleşimden sonra hesaplanıyor; iki kare gerekiyor.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      await expectLater(
        find.byType(StreakAtRiskCard),
        matchesGoldenFile('goldens/streak_4_${frame.$1}.png'),
      );
    });
  }

  /// Kalkan hareketli olduğu için tek kare yeterli değil; döngünün dört
  /// noktası yan yana konur ki alevin salınımı ve parıltı sırası görülebilsin.
  testWidgets('3 — kalkan hareket kareleri', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 300));
    await tester.pumpWidget(frame_(
      Padding(
        padding: const EdgeInsets.all(20),
        child: ColoredBox(
          color: const Color(0xFF041227),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _ShieldFrame(phase: 0.0),
              SizedBox(width: 24),
              _ShieldFrame(phase: 0.25),
              SizedBox(width: 24),
              _ShieldFrame(phase: 0.5),
              SizedBox(width: 24),
              _ShieldFrame(phase: 0.75),
            ],
          ),
        ),
      ),
    ));

    await tester.pump(const Duration(milliseconds: 16));

    await expectLater(
      find.byType(ColoredBox).last,
      matchesGoldenFile('goldens/streak_3_mark_frames.png'),
    );
  });
}

/// Döngünün belirli bir noktasında donmuş buz bloğu.
class _ShieldFrame extends StatelessWidget {
  const _ShieldFrame({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    return StreakFreezeMark(size: 200, animated: false, staticPhase: phase);
  }
}

/// Kalkanın döngüsü kapanıyor mu — **gerçek test**, önizleme değil.
///
/// Alevin salınımındaki frekans çarpanları tam sayı olmazsa döngü başa
/// sardığında alev zıplıyor. Bu, tek kareye bakan golden önizlemesinde
/// görünmüyor; yalnızca uygulamayı izlerken fark ediliyor. Test döngünün son
/// karesi ile ilk karesini piksel piksel karşılaştırır.
void _loopContinuityTest() {
  testWidgets('buz blogu dongusu kapaniyor (alev zıplamıyor)', (tester) async {
    Future<ByteData> render(double phase) async {
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: const ValueKey('shield'),
            child: StreakFreezeMark(
              size: 200,
              animated: false,
              staticPhase: phase,
            ),
          ),
        ),
      );
      await tester.pump();

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('shield')),
      );

      // `toImage` gerçek async iş yapar; testin sahte zaman bölgesinde
      // tamamlanamaz ve test sonsuza kadar asılı kalır. `runAsync` gerçek
      // zamana geçirir.
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data;
      });

      return bytes!;
    }

    // Döngünün son karesi ile ilk karesi. Aradaki fark yalnızca tek karelik
    // normal hareket kadar olmalı.
    final last = await render(0.999);
    final first = await render(0.0);

    var differing = 0;
    final total = last.lengthInBytes ~/ 4;
    for (var i = 0; i < last.lengthInBytes; i += 4) {
      for (var channel = 0; channel < 3; channel++) {
        if ((last.getUint8(i + channel) - first.getUint8(i + channel)).abs() >
            8) {
          differing++;
          break;
        }
      }
    }

    final ratio = differing / total;
    debugPrint('döngü kapanma farkı: ${(ratio * 100).toStringAsFixed(3)}%');

    // Kesirli frekans çarpanıyla (eski hata) bu oran çok daha yükseğe çıkıyor.
    expect(ratio, lessThan(0.005));
  });
}

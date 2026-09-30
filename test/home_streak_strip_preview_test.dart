import 'helpers/preview_fonts.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/home_streak_strip.dart';
import 'package:lingualloop/ui/widgets/streak_week_strip.dart';

/// Ana ekran seri kartı: üç durum + geçişin film şeridi.
///
///   flutter test --update-goldens test/home_streak_strip_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  List<StreakDay> week() {
    final today = DateTime(2026, 8, 10);
    const active = [true, true, false, true, true, true, false];
    const frozen = [false, false, true, false, false, false, false];
    return [
      for (var i = 0; i < 7; i++)
        StreakDay(
          date: today.subtract(Duration(days: 6 - i)),
          active: active[i],
          frozen: frozen[i],
          isToday: i == 6,
        ),
    ];
  }

  Widget cap(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4, top: 18),
        child: Text(s,
            style: const TextStyle(
              color: Color(0xFF8FA0B5),
              fontFamily: 'Nunito',
              fontSize: 17,
              fontWeight: FontWeight.w800,
            )),
      );

  testWidgets('seri karti durumlar', (tester) async {
    const size = Size(750, 940);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF041227),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cap('SERİ HİÇ BAŞLAMAMIŞ — maskot'),
                HomeStreakStrip(
                    scale: 1, streak: 0, days: week(), doneToday: false),
                cap('BUGÜN OYNANMAMIŞ'),
                HomeStreakStrip(
                    scale: 1, streak: 4, days: week(), doneToday: false),
                cap('BUGÜN OYNANDI — normal gün'),
                HomeStreakStrip(
                    scale: 1, streak: 4, days: week(), doneToday: true),
                cap('KİLOMETRE TAŞI — 7. gün'),
                HomeStreakStrip(
                    scale: 1, streak: 7, days: week(), doneToday: true),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Golden'da Image.asset kendiliğinden çözülmez; maskot elle yüklenmeli.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/home_streak_strip.png'),
    );
  });

  testWidgets('gecis filmseridi', (tester) async {
    const cellW = 750.0;
    const cellH = 150.0;
    // Alev salınımı 8000ms sürüyor; kareler tüm süreye yayılmalı.
    const frames = [0, 1, 2, 3, 4, 5, 6, 7];
    final size = Size(cellW, cellH * frames.length + 40);

    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    // Kart animasyonu kendi denetleyicisinde; kareleri yakalamak için
    // `doneToday` çevrilip belirli anlarda pompalanıyor.
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF041227),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: HomeStreakStrip(
                scale: 1, streak: 7, days: week(), doneToday: false),
          ),
        ),
      ),
    );
    await tester.pump();

    // false → true: geçiş başlar.
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF041227),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: HomeStreakStrip(
                scale: 1, streak: 7, days: week(), doneToday: true),
          ),
        ),
      ),
    );

    // Kareleri sırayla yakala.
    for (var i = 0; i < frames.length; i++) {
      await tester.pump(const Duration(milliseconds: 1050));
      await expectLater(
        find.byType(HomeStreakStrip),
        matchesGoldenFile('goldens/home_streak_transition_$i.png'),
      );
    }
  });
}

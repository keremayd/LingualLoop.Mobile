import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/ui/widgets/profile_learning_stats_card.dart';
import 'package:provider/provider.dart';

/// Profilin istatistik + seri şeridi bölümü.
///
///   flutter test --update-goldens test/profile_streak_preview_test.dart
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Inter');
    final bytes = File(
      '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile'
      '/assets/fonts/Inter-SemiBold.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  testWidgets('profil: istatistikler + seri şeridi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(750, 900));

    final today = DateTime(2026, 8, 3);
    const flags = [
      [true, false],
      [true, false],
      [true, false],
      [true, false],
      [true, false],
      [false, true],
      [true, false],
    ];

    final provider = ProfileLearningStatsProvider()
      ..applyPreviewStats(
        ProfileLearningStatsResponse(
          learnedWordCount: 13,
          learnedArticleCount: 5,
          articleInProgressCount: 8,
          reviewPendingCount: 1,
          reviewMistakeCount: 25,
          totalCorrectAnswers: 90,
          totalArticleCorrectAnswers: 56,
          currentStreak: 13,
          longestStreak: 13,
          freezeCount: 1,
          week: [
            for (var i = 0; i < 7; i++)
              DailyActivityDay(
                date: today.subtract(Duration(days: 6 - i)),
                active: flags[i][0],
                frozen: flags[i][1],
              ),
          ],
        ),
      );

    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileLearningStatsProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF041227),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                // Seri kartı artık ProfileLearningStatsCard'ın içinde,
                // başlığın hemen altında — profile_screen.dart ile aynı.
                child: Column(
                  children: const [
                    SizedBox(height: 24),
                    ProfileLearningStatsCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/profile_streak.png'),
    );
  });
}

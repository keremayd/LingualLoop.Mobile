import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'helpers/preview_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/home_screen.dart';
import 'package:lingualloop/ui/app_typography.dart';

final _score = ScoreWithLivesResponse(
  score: 107,
  experience: 107,
  level: 3,
  levelProgress: 7,
  levelBandSize: 50,
  lives: 15,
  maxLives: 15,
  streak: 7,
  playedToday: true,
  streakWeek: List.generate(
      7,
      (i) => DailyActivityDay(
            date: DateTime(2026, 9, 23 + i),
            active: true,
            frozen: false,
          )),
);

class _User extends Fake implements UserService {
  @override
  Future<ApiResponse<ScoreWithLivesResponse>> scoreWithLivesById(
          BuildContext context) async =>
      ApiResponse(data: _score);
}

class _Learning extends ProfileLearningStatsProvider {
  _Learning() {
    applyPreviewStats(ProfileLearningStatsResponse.fromJson({
      'learnedWordCount': 20,
      'learnedArticleCount': 12,
      'reviewPendingCount': 6,
      'currentStreak': 7,
      'longestStreak': 7,
    }));
  }
  @override
  Future<bool> load(BuildContext context) async => true;
}

void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('Home button surfaces with the global style', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<UserService>(create: (_) => _User()),
          ChangeNotifierProvider(
              create: (_) =>
                  ScoreWithLivesProvider()..setScoreWithLives(_score)),
          ChangeNotifierProvider<ProfileLearningStatsProvider>(
              create: (_) => _Learning()),
        ],
        child: MaterialApp(
            theme: ThemeData(
                fontFamily: AppTypography.family,
                textTheme: AppTypography.textTheme),
            debugShowCheckedModeBanner: false,
            home: const HomeScreen())));
    await tester.pump();
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_global_buttons.png'));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

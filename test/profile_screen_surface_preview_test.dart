import 'package:lingualloop/services/FileService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/User.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/profile_screen.dart';
import 'helpers/preview_fonts.dart';

final _score = ScoreWithLivesResponse(
  score: 107,
  experience: 107,
  level: 3,
  levelProgress: 7,
  levelBandSize: 50,
  lives: 15,
  maxLives: 15,
);

class _UserService extends Fake implements UserService {
  @override
  Future<ApiResponse<DailyActivityResponse>?> recordDailyActivity() async =>
      null;
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
      'freezeCount': 2,
      'totalCorrectAnswers': 128,
      'totalArticleCorrectAnswers': 54,
      'week': List.generate(7, (i) => {
        'date': DateTime(2026, 9, 23 + i).toIso8601String(),
        'active': i != 3,
        'frozen': i == 3,
      }),
    }));
  }
  @override
  Future<bool> load(BuildContext context) async => true;
}

void main() {
  setUpAll(loadPreviewFonts);
  for (final width in [320.0, 430.0]) {
    testWidgets('Real profile card surfaces: $width', (tester) async {
      tester.view.physicalSize = Size(width, width * 2.17);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
          providers: [
            Provider<UserService>(create: (_) => _UserService()),
            Provider<LocalFileService>(create: (_) => LocalFileService()),
            ChangeNotifierProvider(
                create: (_) => UserProvider()
                  ..setUser(User(
                    userId: 'preview',
                    firstName: 'Deniz',
                    lastName: 'Yılmaz',
                    displayName: 'Deniz Yılmaz',
                    profilePhotoUrl: null,
                    userNickname: 'deniz',
                    userName: 'preview',
                    userRank: 3,
                  ))),
            ChangeNotifierProvider(
                create: (_) =>
                    ScoreWithLivesProvider()..setScoreWithLives(_score)),
            ChangeNotifierProvider<ProfileLearningStatsProvider>(
                create: (_) => _Learning()),
          ],
          child: const MaterialApp(
              debugShowCheckedModeBanner: false, home: ProfileScreen())));
      await tester.pump();
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
      });
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      if (width == 430) {
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/profile_surface_top.png'));
      }
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (width == 430) {
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('goldens/profile_surface_bottom.png'));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

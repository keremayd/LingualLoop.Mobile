import 'helpers/preview_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/LeagueProgressResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/league_screen.dart';
import 'package:provider/provider.dart';

class _FakeUserService extends UserService {
  _FakeUserService() : super(Dio());

  @override
  Future<ApiResponse<ScoreWithLivesResponse>> scoreWithLivesById(
      BuildContext context) async {
    final data = ScoreWithLivesResponse(
      score: 79,
      // Seviye alanları skorla tutarlı: LevelRules'a göre 79 / 50 + 1 = 2,
      // bant içindeki ilerleme 29.
      experience: 79,
      level: 2,
      levelProgress: 29,
      levelBandSize: 50,
      lives: 4,
      maxLives: 15,
      league: LeagueProgressResponse(
        leagueKey: 'nebula',
        leagueName: 'Nebula',
        rank: 8,
        points: 79,
        minPoints: 70,
        maxPoints: 80,
        pointsToNextLeague: 1,
        progressRatio: 0.9,
        seasonKey: 202607,
        seasonStartsAtUtc: DateTime.utc(2026, 7, 1),
        seasonEndsAtUtc: DateTime.utc(2026, 8, 1),
        leaderboardRank: 3,
        leagueUserCount: 7,
        leaderboard: [
          LeagueLeaderboardEntry(
              rank: 1,
              userId: 'u1',
              displayName: 'Şevval Aydın',
              points: 940,
              isCurrentUser: false),
          LeagueLeaderboardEntry(
              rank: 2,
              userId: 'u2',
              displayName: 'Şevval Aydın',
              points: 930,
              isCurrentUser: false),
          LeagueLeaderboardEntry(
              rank: 3,
              userId: 'me',
              displayName: 'sefa sefa',
              points: 832,
              isCurrentUser: true),
          LeagueLeaderboardEntry(
              rank: 4,
              userId: 'u4',
              displayName: 'Şevval Aydın',
              points: 739,
              isCurrentUser: false),
          LeagueLeaderboardEntry(
              rank: 5,
              userId: 'u5',
              displayName: 'Şevval Aydın',
              points: 690,
              isCurrentUser: false),
          LeagueLeaderboardEntry(
              rank: 6,
              userId: 'u6',
              displayName: 'Şevval Aydın',
              points: 567,
              isCurrentUser: false),
        ],
      ),
    );
    Provider.of<ScoreWithLivesProvider>(context, listen: false)
        .setScoreWithLives(data);
    return ApiResponse(data: data);
  }
}

void main() {
  setUpAll(loadPreviewFonts);
  testWidgets('league screen preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1500));
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserService>(create: (_) => _FakeUserService()),
          Provider<LocalFileService>(create: (_) => LocalFileService()),
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ChangeNotifierProvider<ScoreWithLivesProvider>(
            create: (_) => ScoreWithLivesProvider(),
          ),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LeagueScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await precachePreviewImages(tester);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/league_screen.png'),
    );
  });
}

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
import 'package:lingualloop/ui/widgets/Popups/league_info_popup.dart';
import 'package:provider/provider.dart';

LeagueProgressResponse _sampleLeague({bool solo = false}) =>
    LeagueProgressResponse(
      leagueKey: 'nebula',
      leagueName: 'Nebula',
      rank: 8,
      points: 79,
      minPoints: 70,
      maxPoints: 80,
      pointsToNextLeague: 1,
      progressRatio: 0.9,
      seasonKey: 202610,
      seasonStartsAtUtc: DateTime.utc(2026, 10, 1),
      seasonEndsAtUtc: DateTime.utc(2026, 11, 1),
      leaderboardRank: 3,
      leagueUserCount: 7,
      leaderboard: solo
          ? [
              LeagueLeaderboardEntry(
                  rank: 1,
                  userId: 'me',
                  displayName: 'sefa sefa',
                  points: 79,
                  isCurrentUser: true),
            ]
          : [
              LeagueLeaderboardEntry(
                  rank: 1,
                  userId: 'u1',
                  displayName: 'Şevval Aydın',
                  points: 79,
                  isCurrentUser: false),
              LeagueLeaderboardEntry(
                  rank: 2,
                  userId: 'u2',
                  displayName: 'Şevval Aydın',
                  points: 79,
                  isCurrentUser: false),
              LeagueLeaderboardEntry(
                  rank: 3,
                  userId: 'me',
                  displayName: 'sefa sefa',
                  points: 79,
                  isCurrentUser: true),
              LeagueLeaderboardEntry(
                  rank: 4,
                  userId: 'u4',
                  displayName: 'Şevval Aydın',
                  points: 78,
                  isCurrentUser: false),
              LeagueLeaderboardEntry(
                  rank: 5,
                  userId: 'u5',
                  displayName: 'Şevval Aydın',
                  points: 76,
                  isCurrentUser: false),
              LeagueLeaderboardEntry(
                  rank: 6,
                  userId: 'u6',
                  displayName: 'Şevval Aydın',
                  points: 74,
                  isCurrentUser: false),
            ],
    );

class _FakeUserService extends UserService {
  _FakeUserService({this.solo = false}) : super(Dio());

  final bool solo;

  @override
  Future<ApiResponse<ScoreWithLivesResponse>> scoreWithLivesById(
      BuildContext context) async {
    final data = ScoreWithLivesResponse(
      score: 79,
      experience: 79,
      lives: 4,
      maxLives: 15,
      league: _sampleLeague(solo: solo),
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
    // Sıradaki lige ilerleme ve sezon bilgisi başlık kartında: sıralama ne
    // kadar uzun olursa olsun ekranın üstünde kalsın diye.
    expect(find.text("Kosmoz Ligi'ne 1 puan kaldı"), findsOneWidget);
    expect(find.text('Yenileniyor'), findsOneWidget);
    // Sıralama dolu: tek kişilik sahne gösterilmez.
    expect(find.textContaining('ilk sen ulaştın'), findsNothing);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/league_screen.png'),
    );

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nebula Ligi'), findsNWidgets(2));
    expect(find.text('Kosmoz için 80 puan · 1 puan kaldı'), findsOneWidget);
    expect(find.text('Ekim 2026 sezonu'), findsOneWidget);
    await tester.tap(find.text('ANLADIM'));
    await tester.pumpAndSettle();
    expect(find.text('Nebula Ligi'), findsOneWidget);
  });

  testWidgets('tek kişilik lig: ilk ulaşan sahnesi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1500));
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserService>(create: (_) => _FakeUserService(solo: true)),
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
    expect(find.text("Nebula Ligi'ne ilk sen ulaştın"), findsOneWidget);
    expect(find.text('Yeni rakipler yolda.'), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/league_screen_solo.png'),
    );
  });

  testWidgets('league info card preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF041227),
        body: Center(
          child: LeagueInfoCard(
            league: _sampleLeague(),
            nextLeagueName: 'Kosmoz',
            now: DateTime.utc(2026, 10, 12, 18),
            onClose: () {},
          ),
        ),
      ),
    ));

    await precachePreviewImages(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Sezon bitimine 19 gün 6 saat'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/league_info_popup.png'),
    );
  });
}

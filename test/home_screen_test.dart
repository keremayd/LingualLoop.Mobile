import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/karty_session.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/UpdateLivesResponse.dart';
import 'package:lingualloop/providers/KartyPathProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/home_screen.dart';
import 'package:lingualloop/ui/screens/karty_unit_unlock_screen.dart';
import 'package:lingualloop/ui/widgets/practice_station_marks.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/streak_day_card.dart';
import 'package:provider/provider.dart';

import 'helpers/preview_fonts.dart';

/// Ana ekran Karty Yolu'nun kendisi: duraklar istatistikten beslenir, oyunlar
/// buradan tek dokunuşla açılır, dönüşte bekleyenler sırayla gösterilir.
ScoreWithLivesResponse _score({required bool played, int streak = 3}) =>
    ScoreWithLivesResponse(
      score: 0,
      experience: 40,
      lives: 12,
      maxLives: 15,
      streak: streak,
      longestStreak: 5,
      playedToday: played,
      streakWeek: [
        for (var i = 0; i < 7; i++)
          DailyActivityDay(
            date: DateTime(2026, 11, 1 + i),
            active: i < streak,
            frozen: false,
          ),
      ],
    );

ProfileLearningStatsResponse _stats({
  int learned = 20,
  int articles = 12,
  int reviews = 6,
}) =>
    ProfileLearningStatsResponse.fromJson({
      'learnedWordCount': learned,
      'learnedArticleCount': articles,
      'reviewPendingCount': reviews,
      'currentStreak': 3,
      'longestStreak': 5,
    });

KartyPathResponse _path({int? pendingUnlock}) => KartyPathResponse.fromJson({
      'deckSize': 8,
      'pendingUnlockSequence': pendingUnlock,
      'units': [
        {
          'sequence': 1,
          'title': 'Evde',
          'state': 'current',
          'wordCount': 16,
          'consolidatedCount': 3,
          'unlockGoal': 0.8,
          'steps': [
            {
              'state': 'done',
              'deck': 1,
              'newCount': 8,
              'newGoal': 8,
              'reviewCount': 0,
              'dueCount': 0,
              'words': <dynamic>[],
              'upcomingImageUrls': <String>[],
            },
            {
              'state': 'current',
              'deck': 2,
              'newCount': 3,
              'newGoal': 8,
              'reviewCount': 5,
              'dueCount': 0,
              'words': <dynamic>[],
              'upcomingImageUrls': <String>[],
            },
          ],
        },
        {
          'sequence': 2,
          'title': 'Yolculuk',
          'state': pendingUnlock == null ? 'locked' : 'current',
          'wordCount': 8,
          'consolidatedCount': 0,
          'unlockGoal': 0.8,
          'steps': [
            {
              'state': pendingUnlock == null ? 'locked' : 'upcoming',
              'deck': 1,
              'newCount': 0,
              'newGoal': 8,
              'reviewCount': 0,
              'dueCount': 0,
              'words': <dynamic>[],
              'upcomingImageUrls': <String>[],
            },
          ],
        },
      ],
    });

class _User extends Fake implements UserService {
  _User(this.provider, this.score, this.stats);

  final ScoreWithLivesProvider provider;
  ScoreWithLivesResponse score;
  ProfileLearningStatsResponse stats;
  int spent = 0;

  @override
  Future<ApiResponse<ScoreWithLivesResponse>> scoreWithLivesById(
    BuildContext context,
  ) async {
    provider.setScoreWithLives(score);
    return ApiResponse(data: score);
  }

  @override
  Future<ApiResponse<UpdateLivesResponse>> updateLivesById() async {
    spent += 1;
    return ApiResponse();
  }

  @override
  Future<ApiResponse<ProfileLearningStatsResponse>>
      profileLearningStatsById() async => ApiResponse(data: stats);
}

class _Karty extends Fake implements KartyService {
  KartyPathResponse response = _path();

  @override
  Future<ApiResponse<KartyPathResponse>> path() async =>
      ApiResponse(data: response);
}

class _Home {
  _Home(this.user, this.karty);

  final _User user;
  final _Karty karty;
  String? openedRoute;
  Object? openedArguments;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_Home> _pump(
  WidgetTester tester, {
  bool played = true,
  ProfileLearningStatsResponse? stats,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final scoreProvider = ScoreWithLivesProvider();
  final user = _User(scoreProvider, _score(played: played), stats ?? _stats());
  final karty = _Karty();
  final home = _Home(user, karty);

  Widget game(String route) => Builder(
        builder: (context) {
          home.openedRoute = route;
          home.openedArguments = ModalRoute.of(context)?.settings.arguments;
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ÇIK'),
              ),
            ),
          );
        },
      );

  await tester.pumpWidget(MultiProvider(
    providers: [
      Provider<UserService>.value(value: user),
      Provider<KartyService>.value(value: karty),
      ChangeNotifierProvider.value(value: scoreProvider),
      ChangeNotifierProvider(create: (_) => ProfileLearningStatsProvider()),
      ChangeNotifierProvider(create: (_) => KartyPathProvider(karty)),
    ],
    child: MaterialApp(
      routes: {
        '/kartyquiz': (_) => game('/kartyquiz'),
        '/kartyreview': (_) => game('/kartyreview'),
        '/articlepractice': (_) => game('/articlepractice'),
      },
      home: const HomeScreen(),
    ),
  ));
  await _settle(tester);
  expect(tester.takeException(), isNull);
  return home;
}

Future<void> _closeGame(WidgetTester tester) async {
  await tester.tap(find.text('ÇIK'));
  await _settle(tester);
}

void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('duraklar istatistikten beslenir', (tester) async {
    await _pump(tester);
    expect(find.text('Artikel'), findsOneWidget);
    expect(find.text('8 kart'), findsOneWidget);
    expect(find.text('Rövanş'), findsOneWidget);
    expect(find.text('6 kart'), findsOneWidget);
    expect(find.text('3/8 yeni · 5 tekrar'), findsOneWidget);
  });

  testWidgets('kapalı durak nedenini yazar ve açılmaz', (tester) async {
    final home = await _pump(
      tester,
      stats: _stats(learned: 1, articles: 0, reviews: 0),
    );
    expect(find.text('1 kelime öğren'), findsOneWidget);
    expect(find.text('Hatan yok'), findsOneWidget);

    await tester.tap(find.byType(ArticleDragMark), warnIfMissed: false);
    await tester.tap(find.byType(RevengeCardMark), warnIfMissed: false);
    await _settle(tester);
    expect(home.openedRoute, isNull);
    expect(home.user.spent, 0);
  });

  testWidgets('bütün artikeller tamamsa durak yeni kelime ister',
      (tester) async {
    await _pump(tester, stats: _stats(learned: 8, articles: 8));
    expect(find.text('Yeni kelime öğren'), findsOneWidget);
  });

  testWidgets('DEVAM bileti harcar, oyunu şu anki desteyle açar',
      (tester) async {
    final home = await _pump(tester);
    await tester.tap(find.text('DEVAM ET'));
    await _settle(tester);

    expect(home.user.spent, 1);
    expect(home.openedRoute, '/kartyquiz');
    final session = home.openedArguments! as KartySessionArgs;
    expect(session.unit.number, 1);
    expect(session.deck, 2);
    expect(session.reviewCount, 5);
  });

  testWidgets('Artikel durağı bilet harcar', (tester) async {
    final home = await _pump(tester);
    await tester.tap(find.byType(ArticleDragMark));
    await _settle(tester);
    expect(home.user.spent, 1);
    expect(home.openedRoute, '/articlepractice');
  });

  testWidgets('Rövanş durağı bilet harcamaz', (tester) async {
    final home = await _pump(tester);
    await tester.tap(find.byType(RevengeCardMark));
    await _settle(tester);
    expect(home.user.spent, 0);
    expect(home.openedRoute, '/kartyreview');
  });

  testWidgets('dönüşte duraklar tazelenir', (tester) async {
    final home = await _pump(tester);
    await tester.tap(find.byType(RevengeCardMark));
    await _settle(tester);
    home.user.stats = _stats(reviews: 0);
    await _closeGame(tester);
    expect(find.text('Hatan yok'), findsOneWidget);
  });

  testWidgets('aleve dokununca seri penceresi açılır', (tester) async {
    await _pump(tester);
    expect(find.byType(StreakDayCard), findsNothing);
    await tester.tap(find.byWidgetPredicate(
      (widget) => widget is QuestIcon && widget.questKey == 'streak_three',
    ));
    await _settle(tester);
    expect(find.byType(StreakDayCard), findsOneWidget);
  });

  group('oyundan dönüşte seri penceresi', () {
    testWidgets('günün ilk oyunundan sonra açılır', (tester) async {
      final home = await _pump(tester, played: false);
      await tester.tap(find.byType(RevengeCardMark));
      await _settle(tester);
      home.user.score = _score(played: true, streak: 4);
      await _closeGame(tester);
      expect(find.byType(StreakDayCard), findsOneWidget);
    });

    testWidgets('sonraki oyunlarda açılmaz', (tester) async {
      await _pump(tester, played: true);
      await tester.tap(find.byType(RevengeCardMark));
      await _settle(tester);
      await _closeGame(tester);
      expect(find.byType(StreakDayCard), findsNothing);
    });

    testWidgets('hiç cevap vermeden çıkınca açılmaz', (tester) async {
      await _pump(tester, played: false);
      await tester.tap(find.byType(RevengeCardMark));
      await _settle(tester);
      await _closeGame(tester);
      expect(find.byType(StreakDayCard), findsNothing);
    });

    testWidgets('kapanınca sıradaki ünitenin kutlaması gelir', (tester) async {
      final home = await _pump(tester, played: false);
      await tester.tap(find.byType(RevengeCardMark));
      await _settle(tester);
      home.user.score = _score(played: true, streak: 4);
      home.karty.response = _path(pendingUnlock: 2);
      await _closeGame(tester);
      expect(find.byType(StreakDayCard), findsOneWidget);
      expect(find.byType(KartyUnitUnlockScreen), findsNothing);
      // Kutlamadan önce ünite pencerenin arkasında açılmış görünmez.
      expect(find.textContaining('pekişince açılır'), findsOneWidget);

      Navigator.of(tester.element(find.byType(StreakDayCard))).pop();
      await _settle(tester);
      expect(find.byType(KartyUnitUnlockScreen), findsOneWidget);
    });
  });
}

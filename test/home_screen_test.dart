import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/karty_session.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/models/responses/DailyQuestsResponse.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/UpdateLivesResponse.dart';
import 'package:lingualloop/providers/ArticlePracticeProvider.dart';
import 'package:lingualloop/providers/KartyPathProvider.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/ArticlePracticeService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/QuestService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/home_screen.dart';
import 'package:lingualloop/ui/screens/karty_path_screen.dart';
import 'package:lingualloop/ui/screens/karty_unit_unlock_screen.dart';
import 'package:lingualloop/ui/widgets/practice_station_marks.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';
import 'package:lingualloop/ui/widgets/streak_day_card.dart';
import 'package:lingualloop/ui/widgets/ticket_spend_scene.dart';
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
  String? spendError;

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
    return ApiResponse(errorCode: spendError);
  }

  @override
  Future<ApiResponse<ProfileLearningStatsResponse>>
      profileLearningStatsById() async => ApiResponse(data: stats);
}

/// Oyunun ilk kartlarının ne zaman hazırlandığını sayar.
class _Cards extends KartyProvider {
  int prepared = 0;
  int? unit;
  int? deck;
  int resets = 0;

  @override
  void prepareSession(BuildContext context, {int? unit, int? deck}) {
    prepared += 1;
    this.unit = unit;
    this.deck = deck;
  }

  @override
  void reset() {
    resets += 1;
    super.reset();
  }
}

class _Articles extends ArticlePracticeProvider {
  _Articles() : super(_ArticleService());

  int prepared = 0;

  @override
  void prepareFirstTask() => prepared += 1;
}

class _ArticleService extends Fake implements ArticlePracticeService {}

class _Karty extends Fake implements KartyService {
  KartyPathResponse response = _path();

  @override
  Future<ApiResponse<KartyPathResponse>> path() async =>
      ApiResponse(data: response);
}

/// Görevler verisinin kaç kez istendiğini sayar.
class _QuestService extends Fake implements QuestService {
  int loads = 0;

  @override
  Future<ApiResponse<DailyQuestsResponse>> getDailyQuests() async {
    loads += 1;
    return ApiResponse(
      data: DailyQuestsResponse(
        dayKey: 20261112,
        resetAtUtc: DateTime.utc(2026, 11, 12, 21),
      ),
    );
  }
}

class _Home {
  _Home(this.user, this.karty);

  final _User user;
  final _Karty karty;
  final quests = _QuestService();
  String? openedRoute;
  Object? openedArguments;
  final cards = _Cards();
  final articles = _Articles();
  bool? openedThroughPortal;
}

/// Şu anki düğüm: erişilebilirlik etiketi yaptığı işi söylüyor.
Finder _currentNode() => find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label?.endsWith('Devam et') ?? false),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 24; i++) {
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
          home.openedThroughPortal = ModalRoute.of(context) is GamePortalRoute;
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
      ChangeNotifierProvider<KartyProvider>.value(value: home.cards),
      ChangeNotifierProvider<ArticlePracticeProvider>.value(
        value: home.articles,
      ),
      ChangeNotifierProvider(create: (_) => QuestsProvider(home.quests)),
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

  testWidgets('düğüme dokunmak bileti harcar, oyunu şu anki desteyle açar',
      (tester) async {
    final home = await _pump(tester);
    await tester.tap(_currentNode());
    await tester.pump();
    // Kartlar sahne sürerken inmeye başlar.
    expect(home.cards.prepared, 1);
    expect(home.cards.unit, 1);
    expect(home.cards.deck, 2);
    await _settle(tester);

    expect(home.user.spent, 1);
    expect(home.openedRoute, '/kartyquiz');
    final session = home.openedArguments! as KartySessionArgs;
    expect(session.unit.number, 1);
    expect(session.deck, 2);
    expect(session.reviewCount, 5);
  });

  testWidgets('dokununca sayaç düşer, oyun sahne bitmeden açılmaz',
      (tester) async {
    final home = await _pump(tester);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(_currentNode());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('11'), findsOneWidget);
    expect(find.text('12'), findsNothing);
    expect(home.openedRoute, isNull);

    await _settle(tester);
    expect(home.openedRoute, '/kartyquiz');
  });

  testWidgets('giriş reddedilirse sayaç geri gelir, oyun açılmaz',
      (tester) async {
    final home = await _pump(tester);
    home.user.spendError = 'E9999';

    await tester.tap(_currentNode());
    await _settle(tester);

    expect(find.text('12'), findsOneWidget);
    expect(home.openedRoute, isNull);
    expect(home.cards.resets, 1);
    expect(
      find.image(const AssetImage('assets/icons/ticket.png')),
      findsOneWidget,
    );
  });

  testWidgets('yolda bilet etiketi yok, balon yok', (tester) async {
    await _pump(tester);
    expect(
      find.image(const AssetImage('assets/icons/ticket-one.png')),
      findsNothing,
    );
    expect(find.text('DEVAM ET'), findsNothing);
  });

  testWidgets('etikete dokununca adım penceresi açılır, bilet gitmez',
      (tester) async {
    final home = await _pump(tester);
    await tester.tap(find.text('Deste 2'));
    await _settle(tester);

    expect(find.byType(KartyStepSheet), findsOneWidget);
    expect(home.user.spent, 0);
  });

  testWidgets('bugün henüz oynanmadıysa düğüm aralıklı zıplar', (tester) async {
    await _pump(tester, played: false);
    final bottoms = <double>[];
    // Bir tam döngü; alt kenar ezilişten etkilenmez, yalnız yüksekliği ölçer.
    for (var i = 0; i < 95; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      bottoms.add(tester.getBottomLeft(_currentNode()).dy);
    }
    final rest = bottoms.reduce(math.max);
    final peak = bottoms.reduce(math.min);

    expect(rest - peak, closeTo(12 * 430 / 750, 0.5));
    // Sıçrama döngünün ilk %30'unda, kalanında yerinde durur.
    expect(bottoms.where((y) => y == rest).length, greaterThan(60));
  });

  testWidgets('bugün oynandıysa düğüm zıplamaz', (tester) async {
    await _pump(tester);
    final rest = tester.getBottomLeft(_currentNode()).dy;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.getBottomLeft(_currentNode()).dy, rest);
    }
  });

  testWidgets('bilet sayaçtan kalkar, kesilir, düğüme girince oyun açılır',
      (tester) async {
    final home = await _pump(tester);
    final tickets = find.image(const AssetImage('assets/icons/ticket.png'));
    expect(tickets, findsOneWidget);
    final counter = tester.getCenter(tickets);

    await tester.tap(_currentNode());
    await tester.pump();
    // Sayaç + sahnedeki bilet (kalınlık bandı ve yüz).
    expect(tickets, findsNWidgets(3));
    expect((tester.getCenter(tickets.last) - counter).distance, lessThan(8));

    await tester.pump(const Duration(milliseconds: 600));
    // Yırtıldı: koçan ve gövde ayrı.
    expect(tickets, findsNWidgets(5));
    expect(home.openedRoute, isNull);

    await _settle(tester);
    expect(home.openedRoute, '/kartyquiz');
    expect(home.openedThroughPortal, isTrue);
  });

  testWidgets('sahne sürerken başka oyun açılmaz', (tester) async {
    final home = await _pump(tester);
    await tester.tap(_currentNode());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(RevengeCardMark), warnIfMissed: false);
    await _settle(tester);
    expect(home.openedRoute, '/kartyquiz');
  });

  testWidgets('azaltılmış harekette sahne oynamaz, oyun düz açılır',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final home = await _pump(tester);

    await tester.tap(_currentNode());
    await tester.pump();
    expect(
      find.image(const AssetImage('assets/icons/ticket.png')),
      findsOneWidget,
    );

    await _settle(tester);
    expect(home.openedRoute, '/kartyquiz');
    expect(home.openedThroughPortal, isFalse);
  });

  testWidgets('Rövanş bedelsiz: bilet uçmaz', (tester) async {
    await _pump(tester);
    await tester.tap(find.byType(RevengeCardMark));
    await tester.pump();
    expect(
      find.image(const AssetImage('assets/icons/ticket.png')),
      findsOneWidget,
    );
  });

  testWidgets('Artikel durağı bilet harcar', (tester) async {
    final home = await _pump(tester);
    await tester.tap(find.byType(ArticleDragMark));
    await tester.pump();
    expect(home.articles.prepared, 1);
    expect(home.cards.prepared, 0);
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

  testWidgets('görevler ana ekranla iner, oyundan dönüşte tazelenir',
      (tester) async {
    final home = await _pump(tester);
    // Görevler sekmesi ilk girişte de beklemesin.
    expect(home.quests.loads, 1);

    await tester.tap(find.byType(RevengeCardMark));
    await _settle(tester);
    await _closeGame(tester);
    expect(home.quests.loads, 2);
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/ui/widgets/streak_day_card.dart';
import 'package:lingualloop/ui/widgets/streak_day_scenes.dart';

ScoreWithLivesResponse _score({
  required int streak,
  required int longest,
  required bool playedToday,
}) =>
    ScoreWithLivesResponse(
      score: 0,
      experience: 0,
      level: 1,
      levelProgress: 0,
      levelBandSize: 50,
      lives: 15,
      maxLives: 15,
      streak: streak,
      longestStreak: longest,
      playedToday: playedToday,
    );

String? _sceneKey(ScoreWithLivesResponse score, {bool frozen = false}) =>
    StreakScene.resolve(StreakSceneContext.fromScore(
      score,
      freezeUsedRecently: frozen,
    ))?.key;

void main() {
  test('score-with-lives en uzun seriyi çözer; eski yanıtta sıfır kullanır',
      () {
    final json = {'score': 0, 'lives': 15, 'longestStreak': 8};
    expect(ScoreWithLivesResponse.fromJson(json).longestStreak, 8);
    expect(
        ScoreWithLivesResponse.fromJson({'score': 0, 'lives': 15})
            .longestStreak,
        0);
  });

  test('gerçek seri geçmişi kayıp ve ilk başlangıç sahnelerini ayırır', () {
    expect(_sceneKey(_score(streak: 0, longest: 0, playedToday: false)),
        'beyni_esnet');
    expect(_sceneKey(_score(streak: 0, longest: 8, playedToday: false)),
        'seni_ozledik');
    expect(
        _sceneKey(_score(streak: 0, longest: 8, playedToday: false),
            frozen: true),
        'seni_ozledik');
  });

  test('kişisel en uzun seri özel günleri ve korumayı kapatmaz', () {
    expect(_sceneKey(_score(streak: 4, longest: 4, playedToday: true)),
        'kendi_rekorun');
    expect(_sceneKey(_score(streak: 3, longest: 3, playedToday: true)),
        'istikrar_guclendirir');
    expect(
        _sceneKey(_score(streak: 4, longest: 4, playedToday: true),
            frozen: true),
        'serin_korundu');
    expect(_sceneKey(_score(streak: 4, longest: 8, playedToday: true)), isNull);
    expect(_sceneKey(_score(streak: 4, longest: 4, playedToday: false)),
        'bugun_geri_don');
  });

  testWidgets('ödül sahnesi bir kez yumuşakça girer; azaltılmış harekete uyar',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scene = StreakScene.byKey('kendi_rekorun');

    Widget card({bool disableAnimations = false}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: Scaffold(
              body: Center(
                child: StreakDayCard(
                  scale: 430 / 750,
                  days: 4,
                  message: scene.message,
                  sceneAsset: scene.asset,
                  sceneAspect: scene.aspect,
                  cardColor: scene.cardColor,
                  sceneEdgeColor: scene.sceneEdgeColor,
                  faceOpacity: scene.faceOpacity,
                  sceneZoom: scene.zoom,
                  sceneAnchorY: scene.anchorY,
                  sceneFadeEnd: scene.fadeEnd,
                  animateScene: scene.animateOnEnter,
                  week: const [],
                  playedToday: true,
                ),
              ),
            ),
          ),
        );

    const key = ValueKey('streak-scene-reveal');
    await tester.pumpWidget(card());
    expect(tester.widget<Opacity>(find.byKey(key)).opacity, 0);
    await tester.pump(const Duration(milliseconds: 425));
    expect(tester.widget<Opacity>(find.byKey(key)).opacity,
        inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 425));
    expect(tester.widget<Opacity>(find.byKey(key)).opacity, 1);

    await tester.pumpWidget(card(disableAnimations: true));
    expect(find.byKey(key), findsNothing);
  });
}

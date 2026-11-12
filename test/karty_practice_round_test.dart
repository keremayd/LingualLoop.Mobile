import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/models/karty_path.dart';
import 'package:lingualloop/models/karty_session.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/UpdateScoreResponse.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/GameFeedbackService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/karty_quiz_screen.dart';
import 'package:lingualloop/ui/widgets/karty_answer_actions.dart';
import 'package:provider/provider.dart';

import 'helpers/silent_game_feedback.dart';

/// Vakti gelmiş tekrar yokken Tekrar düğümü pratik açar. Pratiğin sonu
/// yoktu; on dakika oynayan kullanıcı "bunun sonu yok mu?" diye sordu
/// (12 Kas 2026). Tur on cevapla biter, "Pratik tamam!" açılır.
const _image = 'assets/icons/mascot_hello.png';

final _card = Karty(
  kartyId: 1,
  kartyUrl: _image,
  correctText: 'Apfel',
  article: 'der',
  audioUrl: 'https://ses/apfel.mp3',
  mode: KartyCardMode.pickArticle,
  stage: KartyCardStage.practice,
);

class _Cards extends KartyProvider {
  @override
  bool get isLoaded => true;
  @override
  List<Karty> get cards => [_card];
  @override
  void reset() {}
  @override
  Future<bool> loadKarty(BuildContext context,
          {bool reviewMode = false}) async =>
      true;
  @override
  void prefetchNextKarty(BuildContext context, {required bool reviewMode}) {}
}

class _Audio extends Fake implements PronunciationService {
  @override
  final isMuted = ValueNotifier(false);
  @override
  final isSpeaking = ValueNotifier(false);
  @override
  Future<void> play(String? url) async {}
  @override
  Future<void> stop() async {}
}

class _User extends UserService {
  _User() : super(Dio());
  int answers = 0;

  @override
  Future<ApiResponse<UpdateScoreResponse>> updateScoreById(int point,
      {int? kartyId, bool boostActive = false}) async {
    answers += 1;
    return ApiResponse(data: UpdateScoreResponse(userId: 'u', score: 0));
  }

  @override
  Future<ApiResponse<ScoreWithLivesResponse>> scoreWithLivesById(
          BuildContext context) async =>
      ApiResponse();

  @override
  Future<ApiResponse<ProfileLearningStatsResponse>>
      profileLearningStatsById() async => ApiResponse();
}

Future<void> _answer(WidgetTester tester) async {
  await tester.tap(find.byType(KartyDebugAnswerLabel));
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('pratik turu on cevapla biter, özet bir tur daha sunar',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final user = _User();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<KartyProvider>(create: (_) => _Cards()),
        ChangeNotifierProvider(create: (_) => ScoreWithLivesProvider()),
        ChangeNotifierProvider(create: (_) => ProfileLearningStatsProvider()),
        Provider(create: (_) => KartyService(Dio())),
        Provider<UserService>.value(value: user),
        Provider<PronunciationService>.value(value: _Audio()),
        Provider<GameFeedbackService>.value(value: SilentGameFeedback()),
      ],
      child: const MaterialApp(
        home: KartyQuizScreen(
          // Deste yok, vakti gelmiş tekrar yok: oyun baştan pratik.
          session: KartySessionArgs(
            unit: KartyUnit(
              number: 2,
              title: 'Yeni kelimeler',
              state: KartyUnitState.current,
              wordCount: 12,
              consolidatedCount: 1,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (var i = 0; i < 9; i++) {
      await _answer(tester);
    }
    expect(user.answers, 9);
    expect(find.text('Pratik tamam!'), findsNothing);

    await _answer(tester);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(user.answers, 10);
    expect(find.text('Pratik tamam!'), findsOneWidget);
    expect(find.text('BİR TUR DAHA'), findsOneWidget);

    // Bir tur daha: oyun sürer, sayaç yeni turdan başlar.
    await tester.tap(find.text('BİR TUR DAHA'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Pratik tamam!'), findsNothing);
    for (var i = 0; i < 9; i++) {
      await _answer(tester);
    }
    expect(find.text('Pratik tamam!'), findsNothing);
    await _answer(tester);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Pratik tamam!'), findsOneWidget);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}

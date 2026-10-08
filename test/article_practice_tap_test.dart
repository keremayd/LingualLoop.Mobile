import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/ArticlePractice.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/providers/ArticlePracticeProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/services/ArticlePracticeService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/article_practice_screen.dart';
import 'package:lingualloop/ui/widgets/article_target.dart';
import 'package:provider/provider.dart';

class _Service extends Fake implements ArticlePracticeService {}

class _Practice extends ArticlePracticeProvider {
  _Practice() : super(_Service()) {
    status = ArticlePracticeStatus.playing;
    task = const ArticlePracticeTask(
      kartyId: 1,
      nounText: 'Koffer',
      kartyUrl: '',
      articleAttemptCount: 0,
      articleCorrectCount: 0,
      learningStack: 0,
      learningGoal: 5,
    );
  }

  final selectedArticles = <String>[];

  @override
  Future<void> loadNext({int completedTaskRetries = 0}) async {}

  @override
  Future<ArticlePracticeLoadResult?> prepareNext() async => null;

  @override
  Future<ArticlePracticeAnswer?> answer(String article) async {
    if (!canInteract) return null;
    selectedArticles.add(article);
    status = ArticlePracticeStatus.checking;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    final isCorrect = article == 'der';
    answerResult = ArticlePracticeAnswer(
      isAccepted: true,
      isCorrect: isCorrect,
      correctArticle: 'der',
      earnedPoints: isCorrect ? 1 : 0,
      articleAttemptCount: selectedArticles.length,
      articleCorrectCount: isCorrect ? 1 : 0,
    );
    status =
        isCorrect ? ArticlePracticeStatus.correct : ArticlePracticeStatus.wrong;
    notifyListeners();
    return answerResult;
  }
}

class _User extends Fake implements UserService {
  @override
  Future<ApiResponse<ScoreWithLivesResponse>> scoreWithLivesById(
    BuildContext context,
  ) async =>
      ApiResponse(
        data: ScoreWithLivesResponse(
          score: 1,
          experience: 0,
          level: 1,
          levelProgress: 0,
          levelBandSize: 50,
          lives: 15,
          maxLives: 15,
        ),
      );
}

class _Stats extends ProfileLearningStatsProvider {
  @override
  Future<bool> refreshFromService(UserService userService) async => true;
}

Future<_Practice> _pumpPractice(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final practice = _Practice();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ArticlePracticeProvider>.value(value: practice),
        Provider<UserService>(create: (_) => _User()),
        ChangeNotifierProvider<ProfileLearningStatsProvider>(
          create: (_) => _Stats(),
        ),
      ],
      child: const MaterialApp(home: ArticlePracticeScreen()),
    ),
  );
  await tester.pump();
  return practice;
}

void main() {
  testWidgets('Artikel hedeflerine dokunmak cevap verir', (tester) async {
    final practice = await _pumpPractice(tester);

    await tester.tap(find.widgetWithText(ArticleTarget, 'Die'));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(practice.selectedArticles, ['die']);
    expect(find.text('Tekrar dene'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump();
    expect(practice.canInteract, isTrue);

    await tester.tap(find.widgetWithText(ArticleTarget, 'Das'));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(practice.selectedArticles, ['die', 'das']);
    expect(find.text('Tekrar dene'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump();
    expect(practice.canInteract, isTrue);

    await tester.tap(find.widgetWithText(ArticleTarget, 'Der'));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(practice.selectedArticles, ['die', 'das', 'der']);
    expect(find.text('Doğru! der Koffer'), findsOneWidget);
    expect(find.textContaining('+1'), findsNothing);

    await tester.tap(find.widgetWithText(ArticleTarget, 'Der'));
    await tester.pump();
    expect(practice.selectedArticles, ['die', 'das', 'der']);
  });

  testWidgets('Kartı sürükleyerek cevap verme akışı korunur', (tester) async {
    final practice = await _pumpPractice(tester);
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Koffer')));
    await gesture.moveBy(const Offset(90, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(practice.selectedArticles, ['der']);
    expect(find.text('Doğru! der Koffer'), findsOneWidget);
  });
}

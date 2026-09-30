import 'helpers/preview_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/DailyQuestsResponse.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/QuestService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/quests_screen.dart';
import 'package:provider/provider.dart';

class _FakeQuestService extends QuestService {
  _FakeQuestService() : super(Dio());

  @override
  Future<ApiResponse<DailyQuestsResponse>> getDailyQuests() async {
    DailyQuest q(String k, String t, int target, int p, int r,
            {bool claimed = false}) =>
        DailyQuest(
          questKey: k,
          title: t,
          target: target,
          progress: p,
          rewardTickets: r,
          isCompleted: p >= target,
          isClaimed: claimed,
        );

    return ApiResponse(
      data: DailyQuestsResponse(
        dayKey: 20260731,
        resetAtUtc:
            DateTime.now().toUtc().add(const Duration(hours: 7, minutes: 35)),
        quests: [
          q('checkin', 'Güne başla', 1, 1, 5, claimed: true),
          q('correct_five', '5 kelimeyi doğru bil', 5, 3, 10),
          q('learn_three', '3 yeni kelime öğren', 3, 0, 10),
          q('review_two', '2 rövanş kartını geri kazan', 2, 2, 10,
              claimed: true),
          q('streak_three', '3 günlük seriye ulaş', 3, 1, 15),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(loadPreviewFonts);
  testWidgets('quests screen render', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserService>(create: (_) => UserService(Dio())),
          // Başlıktaki bilet sayacı bu sağlayıcıyı okuyor.
          ChangeNotifierProvider<ScoreWithLivesProvider>(
            create: (_) => ScoreWithLivesProvider(),
          ),
          Provider<QuestService>(create: (_) => _FakeQuestService()),
          ChangeNotifierProvider<QuestsProvider>(
            create: (c) => QuestsProvider(c.read<QuestService>()),
          ),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: QuestsScreen(),
        ),
      ),
    );
    // Alınabilir ödülün nabzı sürekli döndüğü için pumpAndSettle asla
    // dönmez; sabit bir kare için pump yeterli.
    await tester.pump(const Duration(milliseconds: 120));

    await precachePreviewImages(tester);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quests_screen.png'),
    );
  });
}

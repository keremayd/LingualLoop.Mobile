import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
    return ApiResponse(
      data: DailyQuestsResponse(
        dayKey: 20260810,
        resetAtUtc: DateTime.now().toUtc().add(const Duration(hours: 8)),
        quests: [
          // Tamamlanmış ve alınabilir: yeşil claim butonu.
          DailyQuest(
            questKey: 'checkin',
            title: 'Güne başla',
            target: 1,
            progress: 1,
            rewardTickets: 1,
            isCompleted: true,
            isClaimed: false,
          ),
          // Devam eden: sönük ödül hapı.
          DailyQuest(
            questKey: 'correct_five',
            title: '5 kelimeyi doğru bil',
            target: 5,
            progress: 2,
            rewardTickets: 2,
            isCompleted: false,
            isClaimed: false,
          ),
          DailyQuest(
            questKey: 'streak_three',
            title: '3 günlük seriye ulaş',
            target: 3,
            progress: 3,
            rewardTickets: 3,
            isCompleted: true,
            isClaimed: false,
          ),
        ],
      ),
    );
  }
}

/// Başlıktaki bilet rozeti — asset gerçekten yüklenerek.
///
///   flutter test --update-goldens test/ticket_badge_preview_test.dart
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Inter');
    final bytes = File(
      '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile'
      '/assets/fonts/Inter-SemiBold.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  testWidgets('bilet rozeti', (tester) async {
    const size = Size(670, 720);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserService>(create: (_) => UserService(Dio())),
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

    // Golden'da Image.asset kendiliğinden çözülmez; elle yüklet.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    // Alınabilir ödülün nabzı sürekli döndüğü için pumpAndSettle asla
    // dönmez; sabit bir kare için pump yeterli.
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ticket_badge.png'),
    );
  });
}

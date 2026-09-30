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

/// Alınabilir ödülün zıplaması — hareketin **tepe** anını yakalar.
///
/// Neden ayrı bir test: sıradan bir golden döngünün başında (dinlenme
/// evresinde) çekilir ve hiçbir şey kanıtlamaz. Burada animasyon zirveye
/// kadar ilerletiliyor, böylece **kalınlık bandının biletle birlikte
/// kalktığı** görülebiliyor. Band yerinde kalsaydı altta ayrı bir koyu
/// bilet gibi açıkta kalırdı — düzeltilen hata buydu.
///
/// Döngü 1900ms; sıçrama ilk %30'unda, zirve o payın %42'sinde
/// → 1900 * 0.30 * 0.42 ≈ 240ms.
///
///   flutter test --update-goldens test/quest_claim_hop_test.dart
class _FakeQuestService extends QuestService {
  _FakeQuestService() : super(Dio());

  @override
  Future<ApiResponse<DailyQuestsResponse>> getDailyQuests() async {
    return ApiResponse(
      data: DailyQuestsResponse(
        dayKey: 20260815,
        resetAtUtc: DateTime.now().toUtc().add(const Duration(hours: 8)),
        quests: [
          DailyQuest(
            questKey: 'checkin',
            title: 'Güne başla',
            target: 1,
            progress: 1,
            rewardTickets: 1,
            isCompleted: true,
            isClaimed: false,
          ),
          DailyQuest(
            questKey: 'correct_five',
            title: '5 kelimeyi doğru bil',
            target: 5,
            progress: 2,
            rewardTickets: 2,
            isCompleted: false,
            isClaimed: false,
          ),
        ],
      ),
    );
  }
}

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

  Future<void> pumpScreen(WidgetTester tester) async {
    const size = Size(430, 700);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;

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
    // Sürekli animasyon var; pumpAndSettle asla dönmez (§4.4).
    await tester.pump(const Duration(milliseconds: 60));
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump();
  }

  testWidgets('zıplama zirvesi — band biletle birlikte kalkar',
      (tester) async {
    await pumpScreen(tester);
    // 60ms zaten geçti; zirve ≈240ms.
    await tester.pump(const Duration(milliseconds: 180));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quest_claim_hop_apex.png'),
    );
  });

  testWidgets('iniş ezilişi', (tester) async {
    await pumpScreen(tester);
    // Eziliş zirvesi: v ≈ 0.345 → ≈655ms.
    await tester.pump(const Duration(milliseconds: 595));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quest_claim_hop_squash.png'),
    );
  });
}

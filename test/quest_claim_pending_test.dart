import 'dart:async';
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

/// **Talep gönderilirken** ödülün görünümü.
///
/// Bu durumun golden'ı yoktu ve iki hata birden barındırıyordu:
///  1. `_pulse.stop()` controller'ı bulunduğu değerde dondurduğu için bilet
///     havadayken basılınca **havada asılı kalıyordu**.
///  2. Bilet tamamen kaldırılıp yerine gösterge konuyor ama kalınlık bandı
///     duruyordu: geriye içi boş koyu bir kabuk ve içinde dönen bir çember
///     kalıyordu.
///
/// Simulator'de dokunamıyoruz (§4.4) ama widget testinde dokunabiliyoruz —
/// bu yüzden bu durum ancak burada yakalanabilir.
///
///   flutter test --update-goldens test/quest_claim_pending_test.dart

/// Talebi **bilerek asılı bırakır**: `isClaiming` true'da kalsın ve o kare
/// yakalanabilsin.
class _HangingQuestService extends QuestService {
  _HangingQuestService() : super(Dio());

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
        ],
      ),
    );
  }

  @override
  Future<ApiResponse<ClaimQuestResponse>> claimReward(String questKey) {
    // Asla tamamlanmaz.
    return Completer<ApiResponse<ClaimQuestResponse>>().future;
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

  testWidgets('talep gönderilirken bilet yerinde ve görünür kalır',
      (tester) async {
    const size = Size(430, 460);
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
          Provider<QuestService>(create: (_) => _HangingQuestService()),
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
    await tester.pump(const Duration(milliseconds: 60));
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });

    // Bileti **havadayken** yakala: zirve ≈240ms. Hatanın ortaya çıktığı an
    // tam olarak buydu.
    await tester.pump(const Duration(milliseconds: 180));

    // Ödüle dokun — barın ucundaki bilet.
    await tester.tap(find.byKey(const ValueKey('claim-checkin')));

    // Basılı görünüm en az 120ms korunuyor; onun ardından ölç.
    await tester.pump(const Duration(milliseconds: 200));

    // Golden'a bakıp "olmuş" demek yetmez — talebin gerçekten askıda
    // olduğunu doğrula, yoksa test yalnızca dinlenme karesini çeker.
    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
      reason: 'Dokunuş claim hedefini bulmalı ve isClaiming true olmalı.',
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quest_claim_pending.png'),
    );
  });
}

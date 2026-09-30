import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/DailyQuestsResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/QuestService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/quests_screen.dart';
import 'package:provider/provider.dart';

/// Başlıktaki bilet sayacının **tavanı** ("13/15").
///
/// Diğer golden'lar bunu göremez: oralarda `ScoreWithLivesProvider` boş,
/// yani `maxLives = 0` ve kesir hiç çizilmiyor. Bakiye burada elle
/// doldurulur ki kesirin gerçekten çizildiği kanıtlansın.
///
///   flutter test --update-goldens test/quest_header_capacity_test.dart
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

ScoreWithLivesResponse _score(int lives, int maxLives) => ScoreWithLivesResponse(
      score: 120,
      experience: 120,
      level: 3,
      levelProgress: 20,
      levelBandSize: 50,
      lives: lives,
      maxLives: maxLives,
    );

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

    final icons = FontLoader('MaterialIcons');
    final iconBytes = File(
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts'
      '/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    icons.addFont(Future.value(ByteData.view(iconBytes.buffer)));
    await icons.load();
  });

  Future<void> pumpWith(WidgetTester tester, int lives, int maxLives) async {
    const size = Size(430, 420);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;

    final scoreProvider = ScoreWithLivesProvider()
      ..setScoreWithLives(_score(lives, maxLives));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserService>(create: (_) => UserService(Dio())),
          ChangeNotifierProvider<ScoreWithLivesProvider>.value(
            value: scoreProvider,
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
    // Alınabilir ödülün zıplaması sürekli; pumpAndSettle dönmez (§4.4).
    await tester.pump(const Duration(milliseconds: 60));
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump();
  }

  testWidgets('tavan kesiri çizilir — 13/15', (tester) async {
    await pumpWith(tester, 13, 15);

    // Golden'a bakıp "olmuş" demek yetmez: kesirin gerçekten basıldığını
    // doğrula, yoksa maxLives=0 olur ve sessizce kaybolur.
    expect(find.text('13'), findsOneWidget);
    expect(find.text('/15'), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quest_header_capacity.png'),
    );
  });

  testWidgets('tavan yüklenmediyse kesir çizilmez', (tester) async {
    await pumpWith(tester, 13, 0);

    expect(find.text('13'), findsOneWidget);
    expect(
      find.text('/0'),
      findsNothing,
      reason: 'Tavan bilinmiyorken "13/0" bakiyeyi yalanlar.',
    );
  });
}

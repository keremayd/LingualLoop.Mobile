import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/DailyQuestsResponse.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/services/QuestService.dart';
import 'package:lingualloop/main.dart' show navigatorKey;
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/screens/quests_screen.dart';
import 'package:provider/provider.dart';

import 'helpers/preview_fonts.dart';

/// Görevler ekranındaki seri koruması: günlük hedef çubuğunun ucunda durur,
/// bütün görevler bitince toplanır (ücretsiz en fazla 1, premium 2).
///
/// Normal koşuda toplama akışı ve dokununca çıkan açıklamalar denetlenir.
/// `FREEZE_CAPTURE=true` golden üretir: sürüyor (3/5), hazır (5/5), alındı.
final _capture = Platform.environment['FREEZE_CAPTURE'] == 'true';

enum _Stage { inProgress, ready, claimed }

class _FakeQuestService extends QuestService {
  _FakeQuestService(this.stage, {this.blockedByCap = false}) : super(Dio());

  _Stage stage;
  final bool blockedByCap;
  int freezeClaims = 0;

  @override
  Future<ApiResponse<DailyQuestsResponse>> getDailyQuests() async {
    final done = stage != _Stage.inProgress;
    DailyQuest q(String k, String t, int target, int r,
            {bool claimed = false}) =>
        DailyQuest(
          questKey: k,
          title: t,
          target: target,
          progress: done || claimed ? target : 0,
          rewardTickets: r,
          isCompleted: done || claimed,
          isClaimed: claimed,
        );
    return ApiResponse(
      data: DailyQuestsResponse(
        dayKey: 20261114,
        resetAtUtc: DateTime.now().toUtc().add(const Duration(hours: 5)),
        quests: [
          q('checkin', 'Güne başla', 1, 1, claimed: true),
          q('correct_five', '5 kelimeyi doğru bil', 5, 2, claimed: true),
          q('learn_three', '3 yeni kelime öğren', 3, 2, claimed: done),
          q('review_two', '2 rövanş kartını geri kazan', 2, 2, claimed: true),
          q('streak_keep', 'Serini sürdür', 1, 3, claimed: done),
        ],
        freezeBonus: QuestFreezeBonus(
          completed: done ? 5 : 3,
          total: 5,
          claimed: stage == _Stage.claimed,
          freezeCount: stage == _Stage.claimed ? 1 : 0,
          freezeCap: 1,
        ),
      ),
    );
  }

  @override
  Future<ApiResponse<ClaimFreezeResponse>> claimFreeze() async {
    freezeClaims++;
    if (blockedByCap) {
      return ApiResponse(
        data: ClaimFreezeResponse(
          claimed: false,
          freezeCount: 1,
          freezeCap: 1,
          blockedByCap: true,
        ),
      );
    }
    stage = _Stage.claimed;
    return ApiResponse(
      data: ClaimFreezeResponse(claimed: true, freezeCount: 1, freezeCap: 1),
    );
  }
}

Widget _host(_FakeQuestService service) => MultiProvider(
      providers: [
        Provider<UserService>(create: (_) => UserService(Dio())),
        ChangeNotifierProvider<ScoreWithLivesProvider>(
          create: (_) => ScoreWithLivesProvider(),
        ),
        Provider<QuestService>.value(value: service),
        ChangeNotifierProvider<QuestsProvider>(
          create: (c) => QuestsProvider(c.read<QuestService>()),
        ),
      ],
      child: const QuestsScreen(),
    );

/// Bildirimler küresel gezgin anahtarıyla gösteriliyor (`AppNotifier`);
/// metinleri doğrulamak için uygulamadaki gibi bağlanır.
Widget _app(_FakeQuestService service) =>
    MaterialApp(navigatorKey: navigatorKey, home: _host(service));

void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('Bütün görevler bitince koruma toplanır ve onaylı kalır',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _FakeQuestService(_Stage.ready);
    await tester.pumpWidget(_app(service));
    // Hazır ödül zıpladığı için pumpAndSettle dönmez (§4.4).
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byKey(const ValueKey('claim-freeze')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(service.freezeClaims, 1);
    expect(find.text('Seri koruması alındı.'), findsOneWidget);

    // Alınmış koruma ikinci talep göndermez, yalnız durumu söyler.
    await tester.tap(find.byKey(const ValueKey('claim-freeze')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(service.freezeClaims, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tamamlanmadan toplanamaz; dokununca ne olduğu söylenir',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _FakeQuestService(_Stage.inProgress);
    await tester.pumpWidget(_app(service));
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byKey(const ValueKey('claim-freeze')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(service.freezeClaims, 0);
    expect(find.text('Seri koruması tüm görevler bitince alınabilir.'),
        findsOneWidget);
  });

  testWidgets('Tavandayken talep tüketilmez, sınır söylenir', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _FakeQuestService(_Stage.ready, blockedByCap: true);
    await tester.pumpWidget(_app(service));
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byKey(const ValueKey('claim-freeze')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(service.freezeClaims, 1);
    expect(find.text('En fazla 1 seri koruması tutulabilir.'), findsOneWidget);

    // Ödül yerinde: koruma harcanınca aynı gün yine alınabilir.
    await tester.tap(find.byKey(const ValueKey('claim-freeze')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(service.freezeClaims, 2);
  });

  testWidgets('Bitince kart bitiş hâline geçer; hazır düğmesi korumayı alır',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _FakeQuestService(_Stage.ready);
    await tester.pumpWidget(_app(service));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Hepsini bitirdin!'), findsOneWidget);
    expect(find.text('Tüm görevleri bitir'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('claim-freeze-chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(service.freezeClaims, 1);
    expect(find.text('Seri koruması alındı.'), findsOneWidget);
    // Alındıktan sonra düğme kalkar, yerinde sakin alt yazı.
    expect(find.byKey(const ValueKey('claim-freeze-chip')), findsNothing);
    expect(find.text('Seri koruması alındı'), findsOneWidget);
  });

  testWidgets('Önizleme: sürüyor, hazır, alındı', (tester) async {
    const phone = Size(430, 932);
    const gap = 24.0;
    tester.view.physicalSize = Size(phone.width * 3 + gap * 2, phone.height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Widget cell(_Stage stage) => SizedBox.fromSize(
          size: phone,
          child: MediaQuery(
            data: const MediaQueryData(size: phone),
            child: _host(_FakeQuestService(stage)),
          ),
        );

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: Colors.black,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: const ValueKey('freeze-bonus-preview'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                cell(_Stage.inProgress),
                const SizedBox(width: gap),
                cell(_Stage.ready),
                const SizedBox(width: gap),
                cell(_Stage.claimed),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 120));
    await precachePreviewImages(tester);
    await tester.pump(const Duration(milliseconds: 120));
    await expectLater(
      find.byKey(const ValueKey('freeze-bonus-preview')),
      matchesGoldenFile('goldens/quests_freeze_bonus.png'),
    );
  }, skip: !_capture);
}

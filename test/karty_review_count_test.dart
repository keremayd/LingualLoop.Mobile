import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:provider/provider.dart';

/// Sunucu tekrarı oyunun payı kadar verir; istemcinin bildirdiği "verilen
/// tekrar" cevaplananlar ile kuyrukta bekleyen tekrarlardan türer. Kuyruktan
/// elenen kart sayıda kalsaydı sunucu payı doldu sanıp tekrarı keser, oyun
/// bitişe hiç varamazdı.
class _Server extends Fake implements KartyService {
  _Server(this.script);

  /// Sırayla dönecek kartlar: kimlik ve aşama.
  final List<(int, KartyCardStage)> script;
  final List<int?> reviewsSent = [];
  var _next = 0;

  @override
  Future<ApiResponse<GetKartyByScoreResponse>> random({
    int? unit,
    int? deck,
    int? reviews,
  }) async {
    reviewsSent.add(reviews);
    final (id, stage) = script[_next++];
    return ApiResponse(
      data: GetKartyByScoreResponse(
        id,
        'W$id',
        'der',
        'u/$id.png',
        0,
        0,
        stage: stage,
      ),
    );
  }
}

class _Files extends Fake implements LocalFileService {
  @override
  Future<String> cacheKartyImage(String imageUrl) async =>
      imageUrl;
}

void main() {
  testWidgets('verilen tekrar = cevaplanan + kuyrukta bekleyen', (
    tester,
  ) async {
    const r = KartyCardStage.review;
    const n = KartyCardStage.newWord;
    const t = KartyCardStage.test;
    final server = _Server([
      (1, r), (2, n), (3, r), // ilk deste
      (4, t), // 1 cevaplanınca önden çekilen
      (3, r), (5, r), // 2 cevaplanınca: 3 kuyrukta, elenir; yerine 5
    ]);
    final provider = KartyProvider()..startSession(unit: 1, deck: 2);
    late BuildContext context;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<KartyService>.value(value: server),
          Provider<LocalFileService>.value(value: _Files()),
        ],
        child: Builder(builder: (c) {
          context = c;
          return const SizedBox();
        }),
      ),
    );

    Future<void> answerTop() async {
      provider.recordAnswered(provider.cards.first);
      provider.prefetchNextKarty(context, reviewMode: false);
      await provider.loadKarty(context);
    }

    await provider.loadKarty(context);
    await provider.whenQueueFilled();
    // Kuyruk boş → 0; 1 (tekrar) kuyrukta → 1; 2 (yeni) eklenince yine 1.
    expect(server.reviewsSent, [0, 1, 1]);
    expect(provider.cards.map((Karty k) => k.kartyId), [1, 2, 3]);

    // 1 cevaplandı (tekrar): 1 cevaplanan + kuyrukta 3 = 2.
    await answerTop();
    expect(server.reviewsSent.last, 2);
    expect(provider.reviewsAnswered, 1);
    expect(provider.cards.map((Karty k) => k.kartyId), [2, 3, 4]);

    // 2 cevaplandı (yeni): sayı değişmez. Sunucu kuyruktaki 3'ü yeniden
    // önerir, elenir; ikinci denemede de sayı aynı kalır.
    await answerTop();
    expect(server.reviewsSent.sublist(4), [2, 2]);
    expect(provider.reviewsAnswered, 1);
    expect(provider.cards.map((Karty k) => k.kartyId), [3, 4, 5]);
  });
}

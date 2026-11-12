import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/Karty.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:provider/provider.dart';

/// Kartlar bilet sahnesi sürerken inmeye başlar; oyun açılınca aynı yüklemeyi
/// devralır. Başka bir oyuna ya da sıfırlanmış oyuna karışmamalı.
class _Server extends Fake implements KartyService {
  Completer<void>? gate;
  var _next = 0;

  @override
  Future<ApiResponse<GetKartyByScoreResponse>> random({
    int? unit,
    int? deck,
    int? reviews,
  }) async {
    await gate?.future;
    final id = ++_next;
    return ApiResponse(
      data: GetKartyByScoreResponse(
        id,
        'W$id',
        'der',
        'u/$id.png',
        0,
        0,
        stage: KartyCardStage.newWord,
      ),
    );
  }
}

/// İlk kartı hemen verir, sonrakileri [rest] açılana kadar bekletir.
class _SlowQueueServer extends _Server {
  final rest = Completer<void>();

  @override
  Future<ApiResponse<GetKartyByScoreResponse>> random({
    int? unit,
    int? deck,
    int? reviews,
  }) async {
    if (_next > 0) await rest.future;
    return super.random(unit: unit, deck: deck, reviews: reviews);
  }
}

class _Files extends Fake implements LocalFileService {
  @override
  Future<String> cacheKartyImage(String imageUrl, int kartyId) async =>
      imageUrl;
}

Future<BuildContext> _context(WidgetTester tester, _Server server) async {
  late BuildContext context;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<KartyService>.value(value: server),
        Provider<LocalFileService>.value(value: _Files()),
      ],
      child: Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    ),
  );
  return context;
}

void main() {
  testWidgets('hazırlanan yükleme aynı desteye bir kez teslim edilir', (
    tester,
  ) async {
    final provider = KartyProvider();
    final context = await _context(tester, _Server());

    provider.prepareSession(context, unit: 1, deck: 2);

    expect(provider.takePreparedLoad(unit: 1, deck: 3), isNull);
    final load = provider.takePreparedLoad(unit: 1, deck: 2);
    expect(load, isNotNull);
    expect(provider.takePreparedLoad(unit: 1, deck: 2), isNull);
    expect(await load, isTrue);
    await provider.whenQueueFilled();
    expect(provider.cards.map((Karty k) => k.kartyId), [1, 2, 3]);
  });

  testWidgets('oyun ilk kartla açılır, destenin kalanı arkada iner', (
    tester,
  ) async {
    final provider = KartyProvider();
    final server = _SlowQueueServer();
    final context = await _context(tester, server);

    // İkinci kart sunucuda beklerken oyun açılabilir.
    expect(await provider.loadKarty(context), isTrue);
    expect(provider.isLoaded, isTrue);
    expect(provider.cards.map((Karty k) => k.kartyId), [1]);

    server.rest.complete();
    await provider.whenQueueFilled();
    expect(provider.cards.map((Karty k) => k.kartyId), [1, 2, 3]);
  });

  testWidgets('sıfırlanınca bekleyen yükleme yeni oyuna kart karıştırmaz', (
    tester,
  ) async {
    final provider = KartyProvider();
    final server = _Server()..gate = Completer<void>();
    final context = await _context(tester, server);

    provider.prepareSession(context, unit: 1, deck: 2);
    provider.reset();
    expect(provider.takePreparedLoad(unit: 1, deck: 2), isNull);

    server.gate!.complete();
    await tester.pump();
    await tester.pump();

    expect(provider.cards, isEmpty);
  });
}

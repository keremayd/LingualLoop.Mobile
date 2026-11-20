import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/services/UserService.dart';
import 'package:stelinda/ui/widgets/league_member_sheet.dart';

/// İsteği saklar, verilen gövdeyle 200 döner.
class _Server implements HttpClientAdapter {
  _Server(this.body);

  final Object body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

UserService _service(_Server server) => UserService(
    Dio(BaseOptions(baseUrl: 'http://localhost/api/', validateStatus: (_) => true))
      ..httpClientAdapter = server);

Future<List<LeagueMemberAction?>> _pumpPanel(WidgetTester tester) async {
  final done = <LeagueMemberAction?>[];
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: LeagueMemberSheetPanel(name: 'Ali Veli', onDone: done.add),
      ),
    ),
  ));
  return done;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({'userId': 'u-1'}));

  testWidgets('Bildir: sebep seçilince o sebeple döner', (tester) async {
    final done = await _pumpPanel(tester);
    expect(find.text('Ali Veli'), findsOneWidget);

    await tester.tap(find.text('Bildir'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Neden bildiriyorsun?'), findsOneWidget);

    await tester.tap(find.text('Uygunsuz fotoğraf'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(done.single, isA<LeagueMemberReport>());
    expect((done.single as LeagueMemberReport).reason, 'photo');
  });

  testWidgets('Engelle: önce onay sorar, onaylanınca engel döner',
      (tester) async {
    final done = await _pumpPanel(tester);

    await tester.tap(find.text('Engelle'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Ali Veli engellensin mi?'), findsOneWidget);
    expect(done, isEmpty);

    await tester.tap(find.text('Engelle'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(done.single, isA<LeagueMemberBlock>());
  });

  testWidgets('Vazgeç hiçbir şey yapmaz', (tester) async {
    final done = await _pumpPanel(tester);
    await tester.tap(find.text('Vazgeç'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(done, [null]);
  });

  test('Engel ve bildirim oturumdaki kullanıcı adına gider', () async {
    final blockServer = _Server({
      'data': {'blocked': true}
    });
    expect(await _service(blockServer).blockUser('u-2'), isTrue);
    expect(blockServer.requests.single.path, 'users/u-1/blocks');
    expect(blockServer.requests.single.data, {'blockedUserId': 'u-2'});

    final reportServer = _Server({
      'data': {'reported': true}
    });
    expect(await _service(reportServer).reportUser('u-2', 'name'), isTrue);
    expect(reportServer.requests.single.path, 'users/u-1/reports');
    expect(reportServer.requests.single.data,
        {'reportedUserId': 'u-2', 'reason': 'name', 'context': 'league'});
  });
}

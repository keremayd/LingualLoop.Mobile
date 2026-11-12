import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/services/GameFeedbackService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:provider/provider.dart';

/// İsteği saklar, verilen durum ve gövdeyle döner.
class _Server implements HttpClientAdapter {
  _Server(this.status, this.body);

  final int status;
  final Object? body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// `TokenInterceptor` 401 dışındaki hataları yanıt olarak döndürüyor; burada
/// aynısını `validateStatus` yapıyor.
UserService _service(_Server server) => UserService(Dio(BaseOptions(
      baseUrl: 'http://localhost/ll-api/',
      validateStatus: (_) => true,
    ))
      ..httpClientAdapter = server);

class _Muted extends Fake implements PronunciationService {
  @override
  final isMuted = ValueNotifier(true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({'userId': 'u-1'}));

  test('Silinen hesapta true döner, istek oturumdaki kullanıcıya gider',
      () async {
    final server = _Server(200, {
      'data': {'deleted': true}
    });
    expect(await _service(server).deleteAccount(), isTrue);
    expect(server.requests.single.method, 'DELETE');
    expect(server.requests.single.path, 'users/u-1/account');
  });

  test('Reddedilen silme false: boş gövdeli 403 ve hata gövdeli 500',
      () async {
    expect(await _service(_Server(403, null)).deleteAccount(), isFalse);
    expect(
      await _service(_Server(500, {'errorCode': 'E4000'})).deleteAccount(),
      isFalse,
    );
  });

  testWidgets('Silinen hesaptan sonra hoş geldin ekranı açılır, oturum biter',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'userId': 'u-1',
      'accessToken': 'erisim',
      'refreshToken': 'yenileme',
    });
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: MaterialApp(
        routes: {'/welcome': (_) => const Text('hoş geldin')},
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => AuthService(Dio()).endDeletedAccount(context),
            child: const Text('profil'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('profil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('hoş geldin'), findsOneWidget);
    // Geri dönülecek sayfa kalmaz.
    expect(find.text('profil'), findsNothing);
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'accessToken'), isNull);
    expect(await storage.read(key: 'userId'), isNull);
  });

  test('Titreşim kapalıyken cevapta titreşim yok, tercih saklanır', () async {
    final haptics = <Object?>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    });
    addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null));

    final feedback = GameFeedbackService(_Muted());
    await pumpEventQueue();
    feedback.correct();
    expect(haptics, ['HapticFeedbackType.lightImpact']);

    await feedback.setVibrationEnabled(false);
    feedback.wrong();
    feedback.complete();
    expect(haptics, hasLength(1));

    // Uygulama yeniden açılınca kayıtlı seçim okunur.
    final restored = GameFeedbackService(_Muted());
    await pumpEventQueue();
    expect(restored.vibrationEnabled.value, isFalse);
  });
}

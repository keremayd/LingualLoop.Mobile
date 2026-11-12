import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/TokenInterceptor.dart';
import 'package:lingualloop/services/AuthenticationService.dart';

class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    return ResponseBody.fromString(
      '{"data":null,"errorCode":"E4103"}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Gelen isteğin başlıklarını saklar, hep 200 döner.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{"data":null}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Süresi dolmuş anahtarı reddeder, yenileme ucu yeni anahtar verir.
/// `yavas/` istekleri reddini yenileme bittikten sonra döner.
class _ExpiredTokenAdapter implements HttpClientAdapter {
  int refreshes = 0;
  final served = <String>[];

  static final _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType]
  };

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    final path = options.uri.path;
    if (path.endsWith('authentication/refresh')) {
      refreshes += 1;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return ResponseBody.fromString(
        '{"data":{"accessToken":"yeni","refreshToken":"yenileme"}}',
        200,
        headers: _json,
      );
    }
    if (options.headers['Authorization'] != 'Bearer yeni') {
      if (path.contains('yavas/')) {
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      return ResponseBody.fromString('{"data":null}', 401, headers: _json);
    }
    served.add(path);
    return ResponseBody.fromString('{"data":null}', 200, headers: _json);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('süresi dolan anahtarda aynı anda giden istekler tek yenileme yapar',
      () async {
    FlutterSecureStorage.setMockInitialValues(
        {'accessToken': 'eski', 'refreshToken': 'yenileme'});
    final adapter = _ExpiredTokenAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/ll-api/'))
      ..httpClientAdapter = adapter;
    final retry = Dio()..httpClientAdapter = adapter;
    dio.interceptors
        .add(TokenInterceptor(AuthService(dio), retryClient: retry));

    // İkisi yenileme sürerken, üçüncüsü yenileme bittikten sonra reddedilir.
    await Future.wait([
      dio.get('karty/path/u1'),
      dio.get('quests/u1'),
      dio.get('yavas/u1'),
    ]);

    expect(adapter.refreshes, 1);
    expect(adapter.served, hasLength(3));
  });

  test('oturum anahtarı her isteğe interceptor\'dan eklenir', () async {
    FlutterSecureStorage.setMockInitialValues({'accessToken': 'anahtar'});
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/ll-api/'));
    final adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(TokenInterceptor(AuthService(dio)));

    // Görevler servisi anahtarı kendisi eklemiyor: önce 401 alıp oturumu
    // yeniliyordu.
    await dio.get('quests/u1');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer anahtar');
  });

  test('giriş, kayıt ve yenileme isteğine anahtar eklenmez', () async {
    FlutterSecureStorage.setMockInitialValues({'accessToken': 'anahtar'});
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/ll-api/'));
    final adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(TokenInterceptor(AuthService(dio)));

    await dio.post('authentication/login', data: {});
    await dio.post('authentication/refresh', data: {});

    expect(
      adapter.requests.map((request) => request.headers['Authorization']),
      everyElement(isNull),
    );
  });

  test('yanlış girişin 401 yanıtı token yenilemeye gönderilmez', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/ll-api/'));
    dio.httpClientAdapter = _UnauthorizedAdapter();
    dio.interceptors.add(TokenInterceptor(AuthService(dio)));

    await expectLater(
      dio.post('authentication/login',
          data: {'email': 'yanlis@example.invalid', 'password': 'yanlis'}),
      throwsA(isA<DioError>().having(
        (error) => error.response?.statusCode,
        'HTTP durum',
        401,
      )),
    );
  });
}

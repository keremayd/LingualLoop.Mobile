import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/TokenInterceptor.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/services/FileService.dart';

class _Files extends LocalFileService {
  @override
  Future<String?> cachedProfilePhotoPath(String userId) async =>
      '/guncel/$userId-profile.jpg';
}

/// Yenileme ucuna ve asıl isteğe sırayla verilecek yanıtlar.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status);

  final int Function(RequestOptions) status;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    final code = status(options);
    if (code == 0) {
      throw DioError(requestOptions: options, type: DioErrorType.other);
    }
    return ResponseBody.fromString(
      jsonEncode({
        'data': code == 200 ? {'accessToken': 'yeni', 'refreshToken': 'r'} : null,
        'errorCode': code == 200 ? null : 'E1',
      }),
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _user = {
  'userId': 'u1',
  'firstName': 'Ada',
  'lastName': 'Y',
  'displayName': 'Ada',
  'profilePhotoUrl': '/eski/klasor/u1-profile.jpg',
  'userNickname': 'ada',
  'userName': 'ada',
  'userRank': 3,
};

Map<String, String> _session() => {
      'userId': 'u1',
      'accessToken': 'a',
      'refreshToken': 'r',
      'sessionUser': jsonEncode(_user),
    };

Dio _dioWith(int Function(RequestOptions) status, {required Dio retry}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/ll-api/'));
  dio.httpClientAdapter = _Adapter(status);
  dio.interceptors.add(TokenInterceptor(AuthService(dio), retryClient: retry));
  return dio;
}

Dio _retryWith(int code) => Dio()..httpClientAdapter = _Adapter((_) => code);

Future<bool> _hasSession() async =>
    await AuthService.restoreSession(files: _Files()) != null;

void main() {
  // navigatorKey ve bildirim katmanı binding ister.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('kayıtlı oturum okunur, fotoğraf yolu yeniden kurulur', () async {
    FlutterSecureStorage.setMockInitialValues(_session());

    final user = await AuthService.restoreSession(files: _Files());

    expect(user?.userId, 'u1');
    expect(user?.profilePhotoUrl, '/guncel/u1-profile.jpg');
  });

  test('token yoksa oturum sayılmaz', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'sessionUser': jsonEncode(_user)});

    expect(await _hasSession(), isFalse);
  });

  test('bozuk kayıt açılışı engellemez', () async {
    FlutterSecureStorage.setMockInitialValues(
        {..._session(), 'sessionUser': 'bozuk'});

    expect(await _hasSession(), isFalse);
  });

  test('clearSession oturumu siler', () async {
    FlutterSecureStorage.setMockInitialValues(_session());

    await AuthService(Dio()).clearSession();

    expect(await _hasSession(), isFalse);
  });

  group('süresi dolmuş token', () {
    int Function(RequestOptions) refreshGives(int code) => (options) =>
        options.path == 'authentication/refresh' ? code : 401;

    test('yenileme reddedilirse oturum silinir', () async {
      FlutterSecureStorage.setMockInitialValues(_session());
      final dio = _dioWith(refreshGives(403), retry: _retryWith(200));

      await expectLater(dio.get('users/u1'), throwsA(isA<DioError>()));

      expect(await _hasSession(), isFalse);
    });

    test('sunucuya ulaşılamazsa oturum kalır', () async {
      FlutterSecureStorage.setMockInitialValues(_session());
      final dio = _dioWith(refreshGives(0), retry: _retryWith(200));

      await expectLater(dio.get('users/u1'), throwsA(isA<DioError>()));

      expect(await _hasSession(), isTrue);
    });

    test('yenileme başarılıysa istek yeni token ile tamamlanır', () async {
      FlutterSecureStorage.setMockInitialValues(_session());
      final dio = _dioWith(refreshGives(200), retry: _retryWith(200));

      final response = await dio.get('users/u1');

      expect(response.statusCode, 200);
      expect(await _hasSession(), isTrue);
    });

    test('yeniden denemede 4xx oturumu kapatmaz', () async {
      FlutterSecureStorage.setMockInitialValues(_session());
      final dio = _dioWith(refreshGives(200), retry: _retryWith(400));

      final response = await dio.get('users/u1');

      expect(response.statusCode, 400);
      expect(await _hasSession(), isTrue);
    });

    test('yeni token da reddedilirse oturum silinir', () async {
      FlutterSecureStorage.setMockInitialValues(_session());
      final dio = _dioWith(refreshGives(200), retry: _retryWith(401));

      await expectLater(dio.get('users/u1'), throwsA(isA<DioError>()));

      expect(await _hasSession(), isFalse);
    });
  });
}

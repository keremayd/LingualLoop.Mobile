import 'dart:typed_data';

import 'package:dio/dio.dart';
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

void main() {
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

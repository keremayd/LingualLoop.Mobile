import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/services/AuthenticationService.dart';

Response<dynamic> _response(int status, Object? body) => Response(
      requestOptions: RequestOptions(path: 'authentication/register'),
      statusCode: status,
      data: body,
    );

void main() {
  test('Başarılı yanıt geçer', () {
    expect(() => ensureSuccess(_response(200, {'data': {}})), returnsNormally);
  });

  test('Hata yanıtı, gövdesiyle birlikte DioError olur', () {
    final body = {
      'errorList': {
        'errorCode': ['DuplicateEmail'],
      },
    };
    expect(
      () => ensureSuccess(_response(400, body)),
      throwsA(isA<DioError>()
          .having((e) => e.response?.statusCode, 'durum', 400)
          .having((e) => e.response?.data, 'gövde', body)),
    );
  });
}

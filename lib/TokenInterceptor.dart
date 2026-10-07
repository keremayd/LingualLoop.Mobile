import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'services/AuthenticationService.dart';
import 'main.dart';

class TokenInterceptor extends Interceptor {
  final AuthService authService;
  final _storage = const FlutterSecureStorage();
  Dio _dio = Dio();

  TokenInterceptor(this.authService);

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    // Yanlış giriş bilgileri için dönen 401, süresi dolmuş oturum değildir.
    // Ekran bu yanıtı alıp kullanıcıya giriş hatasını göstermelidir.
    if (err.requestOptions.path == 'authentication/login' ||
        err.requestOptions.path == 'authentication/google-login') {
      return handler.next(err);
    }

    if (err.type == DioErrorType.connectTimeout ||
        err.type == DioErrorType.sendTimeout ||
        err.type == DioErrorType.receiveTimeout ||
        err.type == DioErrorType.other) {
      AppNotifier.showMessage("Timeout hatası! Daha sonra tekrar deneyin.");

      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      var response = await authService.refreshToken();
      if (!response) {
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/signin', (route) => false);
      }

      // Hatalı isteği tekrar gönderiyoruz
      try {
        var accessToken = await _storage.read(key: 'accessToken');
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer $accessToken';

        final updatedHeaders = Map<String, dynamic>.from(requestOptions.headers)
          ..['Authorization'] = 'Bearer $accessToken';

        final result = await _dio.request(
          requestOptions.baseUrl + requestOptions.path,
          options: Options(
            method: requestOptions.method, // (POST, GET, etc.)
            headers: updatedHeaders,
            responseType: requestOptions.responseType,
            followRedirects: requestOptions.followRedirects,
            validateStatus: requestOptions.validateStatus,
          ),
          data: requestOptions.data, // varsa body
        );

        handler.resolve(result); // Hatalı isteği başarıyla sonuçlandırıyoruz
      } catch (e) {
        // Yeniden deneyemediğinde, token refresh başarısızsa login sayfasına yönlendir
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/signin', (route) => false);
      }
      return;
    }

    handler.resolve(err.response!);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'services/AuthenticationService.dart';
import 'main.dart';

class TokenInterceptor extends Interceptor {
  final AuthService authService;
  final _storage = const FlutterSecureStorage();
  final Dio _dio;

  TokenInterceptor(this.authService, {Dio? retryClient})
      : _dio = retryClient ?? Dio();

  /// Oturum sunucuda bitti: sonraki açılış ana ekrandan başlamasın diye
  /// kayıtlar da silinir.
  Future<void> _endSession() async {
    await authService.clearSession();
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/signin', (route) => false);
  }

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
      final bool refreshed;
      try {
        refreshed = await authService.refreshToken();
      } catch (_) {
        // Sunucuya ulaşılamadı: oturum bitmiş değil, kapatılmaz.
        return handler.next(err);
      }
      if (!refreshed) {
        await _endSession();
        return handler.next(err);
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
      } on DioError catch (retryError) {
        // Yalnız yeni token da reddedildiyse oturum bitmiştir. Başka hata
        // (ağ, 4xx) kullanıcıyı girişe atmamalı.
        if (retryError.response?.statusCode == 401) await _endSession();
        final response = retryError.response;
        if (response != null && response.statusCode != 401) {
          return handler.resolve(response);
        }
        return handler.next(retryError);
      }
      return;
    }

    handler.resolve(err.response!);
  }
}

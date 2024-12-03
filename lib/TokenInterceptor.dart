import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'services/auth_service.dart';
import 'main.dart'; // Global navigatorKey’i burada import ediyoruz


class TokenInterceptor extends Interceptor {
  final AuthService authService;


  TokenInterceptor(this.authService);

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      var response = await authService.refreshToken();
      if(!response){
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      }

      return;
    }

    handler.resolve(err.response!);
  }
}

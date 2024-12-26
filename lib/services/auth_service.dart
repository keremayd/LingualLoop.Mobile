import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/AuthenticateResponse.dart';
import 'package:lingualloop/models/responses/RefreshTokenResponse.dart';
import 'package:flutter/cupertino.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:provider/provider.dart';


import '../models/User.dart';

class AuthService {
  Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthService(this._dio);

  Dio get dio => _dio;

  Future<ApiResponse<AuthenticateResponse>> login(String email, String password, BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final response = await _dio.post('authentication/login', data: {
    'userName': email,
    'password': password,
    });

    var apiResponse = ApiResponse<AuthenticateResponse>.fromJson(
      response.data,
          (data) => AuthenticateResponse.fromJson(data as Map<String, dynamic>),
    );

    // Update UserProvider
    userProvider.setUser(
      User(
        userId: apiResponse.data!.userId,
        userNickname: apiResponse.data!.userNickname
      ),
    );

    await _storage.write(key: 'userId', value: apiResponse.data?.userId);
    await _storage.write(key: 'accessToken', value: apiResponse.data?.accessToken);
    await _storage.write(key: 'refreshToken', value: apiResponse.data?.refreshToken);

    return apiResponse;
  }

  Future<bool> isAccessTokenExpired() async {
    return true;
  }

  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    final accessToken = await _storage.read(key: 'accessToken');
    final response = await _dio.post('authentication/refresh', data: {
      'refreshToken': refreshToken,
      'accessToken': accessToken
    });

    var apiResponse = ApiResponse<RefreshTokenResponse>.fromJson(
      response.data,
          (data) => RefreshTokenResponse.fromJson(data as Map<String, dynamic>),
    );

    if (response.statusCode == 200) {
      await _storage.write(key: 'accessToken', value: apiResponse.data?.accessToken);
      return true;
    }

    return false;
  }
}

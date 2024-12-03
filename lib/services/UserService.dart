import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/responses/GetQuestionByScoreResponse.dart';
import 'package:lingualloop/models/responses/UpdateScoreResponse.dart';

import '../models/ApiResponse.dart';
import '../models/User.dart';

class UserService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  UserService(this._dio);

  Future<ApiResponse<UpdateScoreResponse>> updateScoreById(int point) async {
    final userId = await _storage.read(key: 'userId');
    final response = await _dio.post('users/updateScore', data: {
    'userId': userId,
    'point': point,
    });

    var apiResponse = ApiResponse<UpdateScoreResponse>.fromJson(
      response.data,
          (data) => UpdateScoreResponse.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse;
  }
}
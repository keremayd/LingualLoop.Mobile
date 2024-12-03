import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/responses/GetQuestionByScoreResponse.dart';

import '../models/ApiResponse.dart';
import '../models/User.dart';

class QuestionService {
  final Dio _dio;
  final _storage = FlutterSecureStorage();
  GetQuestionByScoreResponse? question;

  QuestionService(this._dio);

  Future<void> test() async {
  }

  Future<ApiResponse<GetQuestionByScoreResponse>> random() async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.get('questions/random/$userId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    var apiResponse = ApiResponse<GetQuestionByScoreResponse>.fromJson(
      response.data,
          (data) => GetQuestionByScoreResponse.fromJson(data as Map<String, dynamic>),
    );
    question = apiResponse.data;

    return apiResponse;
  }
}
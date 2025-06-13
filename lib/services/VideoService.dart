import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/responses/GetQuestionByScoreResponse.dart';
import 'package:lingualloop/models/responses/GetSavedVideosByIdResponse.dart';

import '../models/ApiResponse.dart';

class VideoService {
  final Dio _dio;
  final _storage = FlutterSecureStorage();
  GetQuestionByScoreResponse? question;

  VideoService(this._dio);

  Future<ApiResponse<List<GetSavedVideosByIdResponse>>> savedVideos() async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.get('videos/saved/$userId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    var apiResponse = ApiResponse<List<GetSavedVideosByIdResponse>>.fromJson(
      response.data,
          (badge) => (badge as List)
          .map((e) => GetSavedVideosByIdResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    return apiResponse;
  }

  Future<ApiResponse<GetQuestionByScoreResponse>> random() async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.get('videos/random/$userId',
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
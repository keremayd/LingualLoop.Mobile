import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';

import '../models/ApiResponse.dart';

class KartyService {
  final Dio _dio;
  final _storage = FlutterSecureStorage();
  GetKartyByScoreResponse? kartyQuestion;

  KartyService(this._dio);

  Future<ApiResponse<GetKartyByScoreResponse>> random() async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.get(
      'karty/random/$userId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    var apiResponse = ApiResponse<GetKartyByScoreResponse>.fromJson(
      response.data,
      (data) => GetKartyByScoreResponse.fromJson(data as Map<String, dynamic>),
    );
    kartyQuestion = apiResponse.data;

    return apiResponse;
  }

  Future<ApiResponse<GetKartyByScoreResponse>> randomWrong() async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.get(
      'karty/wrong/random/$userId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    var apiResponse = ApiResponse<GetKartyByScoreResponse>.fromJson(
      response.data,
      (data) => GetKartyByScoreResponse.fromJson(data as Map<String, dynamic>),
    );
    kartyQuestion = apiResponse.data;

    return apiResponse;
  }

  Future<void> recordWrongKarty(int kartyId) async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    await _dio.post(
      'karty/wrong',
      data: {
        'userId': userId,
        'kartyId': kartyId,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<void> resolveWrongKartyReview(int kartyId, bool isMastered) async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    await _dio.post(
      'karty/wrong/review',
      data: {
        'userId': userId,
        'kartyId': kartyId,
        'isMastered': isMastered,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}

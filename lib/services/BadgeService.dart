import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/responses/GetBadgesByIdResponse.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';

import '../models/ApiResponse.dart';

class BadgeService {
  final Dio _dio;
  final _storage = FlutterSecureStorage();
  GetKartyByScoreResponse? kartyQuestion;

  BadgeService(this._dio);

  Future<ApiResponse<List<GetBadgesByIdResponse>>> getBadgesById() async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.get('badges/$userId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    var apiResponse = ApiResponse<List<GetBadgesByIdResponse>>.fromJson(
      response.data,
          (badge) => (badge as List)
              .map((e) => GetBadgesByIdResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

    return apiResponse;
  }
}
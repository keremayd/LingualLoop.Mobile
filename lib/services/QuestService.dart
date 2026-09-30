import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/DailyQuestsResponse.dart';

class QuestService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  QuestService(this._dio);

  Future<ApiResponse<DailyQuestsResponse>> getDailyQuests() async {
    final userId = await _storage.read(key: 'userId');
    final response = await _dio.get('quests/$userId');

    return ApiResponse<DailyQuestsResponse>.fromJson(
      response.data,
      (data) => DailyQuestsResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ClaimQuestResponse>> claimReward(String questKey) async {
    final userId = await _storage.read(key: 'userId');
    final response = await _dio.post(
      'quests/claim',
      data: {
        'userId': userId,
        'questKey': questKey,
      },
    );

    return ApiResponse<ClaimQuestResponse>.fromJson(
      response.data,
      (data) => ClaimQuestResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}

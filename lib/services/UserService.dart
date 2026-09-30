import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/responses/ProfileLearningStatsResponse.dart';
import 'package:lingualloop/models/responses/DailyActivityResponse.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/UpdateLivesResponse.dart';
import 'package:lingualloop/models/responses/UpdateScoreResponse.dart';
import 'package:lingualloop/models/responses/AcknowledgeLeaguePromotionResponse.dart';
import 'package:provider/provider.dart';

import '../models/ApiResponse.dart';
import '../models/responses/UploadUserFileResponse.dart';
import '../providers/ScoreWithLivesProvider.dart';

class UserService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  UserService(this._dio);

  Future<ApiResponse<DailyActivityResponse>?> recordDailyActivity() async {
    final userId = await _storage.read(key: 'userId');
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cacheKey = 'lastDailyActivityCheckInDate_$userId';
    final lastCheckInDate = await _storage.read(key: cacheKey);

    if (lastCheckInDate == today) {
      return null;
    }

    final response = await _dio.post('users/$userId/daily-activity');

    var apiResponse = ApiResponse<DailyActivityResponse>.fromJson(
      response.data,
      (data) => DailyActivityResponse.fromJson(data as Map<String, dynamic>),
    );

    // Önbellek "bugünün girişi kapandı" demektir. Seri risk altındaysa
    // kapanmamıştır: kullanıcı korumayı kullanıp kullanmayacağına henüz karar
    // vermedi. Burada yazsaydık uygulama kapanıp açıldığında soru bir daha
    // sorulamaz, seri belirsiz durumda asılı kalırdı.
    final settled = apiResponse.errorCode == null &&
        !(apiResponse.data?.streakAtRisk ?? false);

    if (settled) {
      await _storage.write(
        key: cacheKey,
        value: today,
      );
    }

    return apiResponse;
  }

  /// Seri koruma kararını backend'e bildirir.
  ///
  /// [useFreeze] true ise kaçırılan gün sayısı kadar koruma harcanır ve seri
  /// devam eder; false ise seri 1'e döner ama korumalar **yanmaz** — kullanıcı
  /// bilinçli olarak "bu seri için harcamaya değmez" demiştir.
  Future<ApiResponse<DailyActivityResponse>?> resolveStreakFreeze(
    bool useFreeze,
  ) async {
    final userId = await _storage.read(key: 'userId');
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final response = await _dio.post(
      'users/$userId/streak/resolve-freeze',
      queryParameters: {'useFreeze': useFreeze},
    );

    final apiResponse = ApiResponse<DailyActivityResponse>.fromJson(
      response.data,
      (data) => DailyActivityResponse.fromJson(data as Map<String, dynamic>),
    );

    // Karar verildi; bugünün girişi artık kapandı.
    if (apiResponse.errorCode == null) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await _storage.write(
        key: 'lastDailyActivityCheckInDate_$userId',
        value: today,
      );
    }

    return apiResponse;
  }

  Future<ApiResponse<ScoreWithLivesResponse>> scoreWithLivesById(
      BuildContext context) async {
    final scoreWithLivesProvider =
        Provider.of<ScoreWithLivesProvider>(context, listen: false);
    final userId = await _storage.read(key: 'userId');
    final response = await _dio.get('users/$userId/score-with-lives');

    var apiResponse = ApiResponse<ScoreWithLivesResponse>.fromJson(
      response.data,
      (data) => ScoreWithLivesResponse.fromJson(data as Map<String, dynamic>),
    );

    scoreWithLivesProvider.setScoreWithLives(apiResponse.data!);

    return apiResponse;
  }

  Future<ApiResponse<ProfileLearningStatsResponse>>
      profileLearningStatsById() async {
    final userId = await _storage.read(key: 'userId');
    final response = await _dio.get('users/$userId/learning-stats');

    var apiResponse = ApiResponse<ProfileLearningStatsResponse>.fromJson(
      response.data,
      (data) => ProfileLearningStatsResponse.fromJson(
        data as Map<String, dynamic>,
      ),
    );

    return apiResponse;
  }

  /// [point] cevabın **yönü**: doğruda `1`, yanlışta `-1`. Boost çarpanı
  /// buraya karıştırılmaz — bir dönem doğru cevap boost açıkken `3` olarak
  /// gönderiliyordu ve sunucu o sayıyı gizli zorluk termostatına da
  /// yazıyordu, yani boost zorluğu üçe katlıyordu. Çarpanı [boostActive]
  /// taşıyor; hangi sayacın çarpılacağına sunucu karar veriyor.
  Future<ApiResponse<UpdateScoreResponse>> updateScoreById(int point,
      {int? kartyId, bool boostActive = false}) async {
    final userId = await _storage.read(key: 'userId');
    final response = await _dio.post('users/update-score', data: {
      'userId': userId,
      'point': point,
      'boostActive': boostActive,
      'kartyId': kartyId,
    });

    var apiResponse = ApiResponse<UpdateScoreResponse>.fromJson(
      response.data,
      (data) => UpdateScoreResponse.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse;
  }

  Future<ApiResponse<AcknowledgeLeaguePromotionResponse>>
      acknowledgeLeaguePromotion() async {
    final userId = await _storage.read(key: 'userId');
    final response =
        await _dio.post('users/$userId/league/promotion/acknowledge');

    return ApiResponse<AcknowledgeLeaguePromotionResponse>.fromJson(
      response.data,
      (data) => AcknowledgeLeaguePromotionResponse.fromJson(
        data as Map<String, dynamic>,
      ),
    );
  }

  Future<ApiResponse<UpdateLivesResponse>> updateLivesById() async {
    final userId = await _storage.read(key: 'userId');
    final response =
        await _dio.post('users/update-lives', data: {'userId': userId});

    var apiResponse = ApiResponse<UpdateLivesResponse>.fromJson(
      response.data,
      (data) => UpdateLivesResponse.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse;
  }

  Future<ApiResponse<UploadUserFileResponse>> updateProfilePhotoById(
      File file) async {
    final userId = await _storage.read(key: 'userId');
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    final response =
        await _dio.post('users/$userId/upload-profile-photo', data: formData);

    var apiResponse = ApiResponse<UploadUserFileResponse>.fromJson(
      response.data,
      (data) => UploadUserFileResponse.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse;
  }
}

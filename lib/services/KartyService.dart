import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/responses/GetKartyByScoreResponse.dart';
import 'package:lingualloop/models/responses/KartyPathResponse.dart';
import 'package:lingualloop/models/responses/KartySessionStatusResponse.dart';
import 'package:lingualloop/models/responses/ResolveWrongKartyReviewResponse.dart';

import '../models/ApiResponse.dart';

class KartyService {
  final Dio _dio;
  final _storage = FlutterSecureStorage();
  GetKartyByScoreResponse? kartyQuestion;

  KartyService(this._dio);

  /// Sıradaki kart. [unit] ve [deck] oyunun destesi: yeni kelime yalnız
  /// oradan gelir (sunucuda `KartyScheduler`). [reviews] oyunda şimdiye kadar
  /// verilen tekrar kartı sayısı; tekrar oyunun payı kadar gelir.
  Future<ApiResponse<GetKartyByScoreResponse>> random({
    int? unit,
    int? deck,
    int? reviews,
  }) async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.get(
      'karty/random/$userId',
      queryParameters: {
        if (unit != null) 'unit': unit,
        if (deck != null) 'deck': deck,
        if (reviews != null) 'reviews': reviews,
      },
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

  /// Karty Yolu: üniteler ve desteleri.
  Future<ApiResponse<KartyPathResponse>> path() async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.get(
      'karty/path/$userId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return ApiResponse<KartyPathResponse>.fromJson(
      response.data,
      (data) => KartyPathResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Oyunun durumu: destesi bitti mi, tekrar payı doldu mu ([reviews] =
  /// oyunda cevaplanan tekrar). Oyun her cevaptan sonra sorar; bitince
  /// özeti gösterir.
  Future<ApiResponse<KartySessionStatusResponse>> sessionStatus({
    required int unit,
    int? deck,
    int reviews = 0,
  }) async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.get(
      'karty/session/$userId',
      queryParameters: {
        'unit': unit,
        if (deck != null) 'deck': deck,
        'reviews': reviews,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return ApiResponse<KartySessionStatusResponse>.fromJson(
      response.data,
      (data) =>
          KartySessionStatusResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Ünite açılış kutlaması görüldü; patika onu bir daha göstermez.
  Future<ApiResponse<Object?>> acknowledgeUnitUnlock() async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.post(
      'karty/path/$userId/unlock/acknowledge',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return ApiResponse<Object?>.fromJson(
      response.data,
      (data) => data,
    );
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

  /// Tanışma kartındaki "Anladım" onayı. Bundan sonra o kelime yazım sorusu
  /// olarak gelmeye başlar.
  Future<void> recordKartyIntroduction(int kartyId) async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    await _dio.post(
      'karty/introduced',
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

  Future<ResolveWrongKartyReviewResponse?> resolveWrongKartyReview(
    int kartyId,
    bool isMastered,
  ) async {
    final token = await _storage.read(key: 'accessToken');
    final userId = await _storage.read(key: 'userId');

    final response = await _dio.post(
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

    final apiResponse = ApiResponse<ResolveWrongKartyReviewResponse>.fromJson(
      response.data,
      (data) => ResolveWrongKartyReviewResponse.fromJson(
        data as Map<String, dynamic>,
      ),
    );

    return apiResponse.data;
  }
}

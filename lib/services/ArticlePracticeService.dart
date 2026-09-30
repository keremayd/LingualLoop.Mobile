import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/ArticlePractice.dart';
import 'package:lingualloop/services/FileService.dart';

class ArticlePracticeService {
  ArticlePracticeService(this._dio, this._localFileService);

  final Dio _dio;
  final LocalFileService _localFileService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<ApiResponse<ArticlePracticeLoadResult>> getNextTask({
    int? preferredKartyId,
  }) async {
    final userId = await _storage.read(key: 'userId');
    final response = await _dio.get(
      'article-practice/next/$userId',
      queryParameters: preferredKartyId == null
          ? null
          : {'preferredKartyId': preferredKartyId},
    );
    final apiResponse = ApiResponse<ArticlePracticeLoadResult>.fromJson(
      response.data,
      (data) => ArticlePracticeLoadResult.fromJson(
        data as Map<String, dynamic>,
      ),
    );
    final result = apiResponse.data;
    if (result == null) return apiResponse;

    try {
      final cachedTasks = await Future.wait([
        _cacheTask(result.task),
        _cacheTask(result.nextTask),
      ]);
      return ApiResponse<ArticlePracticeLoadResult>(
        data: result.withTasks(
          task: cachedTasks[0],
          nextTask: cachedTasks[1],
        ),
        message: apiResponse.message,
        errorCode: apiResponse.errorCode,
        code: apiResponse.code,
      );
    } catch (_) {
      return apiResponse;
    }
  }

  Future<ArticlePracticeTask?> _cacheTask(ArticlePracticeTask? task) async {
    if (task == null || task.kartyUrl.isEmpty) return task;
    final imagePath = await _localFileService.cacheKartyImage(
      task.kartyUrl,
      task.kartyId,
    );
    return task.withLocalImage(imagePath);
  }

  Future<ApiResponse<ArticlePracticeAnswer>> answer({
    required int kartyId,
    required String selectedArticle,
  }) async {
    final userId = await _storage.read(key: 'userId');
    final response = await _dio.post(
      'article-practice/answer',
      data: {
        'userId': userId,
        'kartyId': kartyId,
        'selectedArticle': selectedArticle,
      },
    );
    return ApiResponse<ArticlePracticeAnswer>.fromJson(
      response.data,
      (data) => ArticlePracticeAnswer.fromJson(
        data as Map<String, dynamic>,
      ),
    );
  }
}

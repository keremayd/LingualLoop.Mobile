import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lingualloop/models/responses/ScoreWithLivesResponse.dart';
import 'package:lingualloop/models/responses/UpdateLivesResponse.dart';
import 'package:lingualloop/models/responses/UpdateScoreResponse.dart';
import 'package:provider/provider.dart';

import '../models/ApiResponse.dart';
import '../models/responses/UploadUserFileResponse.dart';
import '../providers/ScoreWithLivesProvider.dart';

class UserService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  UserService(this._dio);

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

  Future<ApiResponse<UpdateScoreResponse>> updateScoreById(int point,
      {int? kartyId}) async {
    final userId = await _storage.read(key: 'userId');
    final response = await _dio.post('users/update-score', data: {
      'userId': userId,
      'point': point,
      'kartyId': kartyId,
    });

    var apiResponse = ApiResponse<UpdateScoreResponse>.fromJson(
      response.data,
      (data) => UpdateScoreResponse.fromJson(data as Map<String, dynamic>),
    );

    return apiResponse;
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

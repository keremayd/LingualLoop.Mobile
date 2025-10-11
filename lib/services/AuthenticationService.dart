import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:lingualloop/Utils/AppNotifier.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/Requests/SignUpRequest.dart';
import 'package:lingualloop/models/responses/AuthenticateResponse.dart';
import 'package:lingualloop/models/responses/RefreshTokenResponse.dart';
import 'package:flutter/cupertino.dart';
import 'package:lingualloop/models/responses/SignUpResponse.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';


import '../models/User.dart';
import '../ui/screens/login_screen.dart';

class AuthService {
  Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthService(this._dio);

  Dio get dio => _dio;

  Future<ApiResponse<AuthenticateResponse>> signIn(String email, String password, BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final fileService = LocalFileService();

    final response = await _dio.post('authentication/login', data: {
    'email': email,
    'password': password,
    });

    var apiResponse = ApiResponse<AuthenticateResponse>.fromJson(
      response.data,
          (data) => AuthenticateResponse.fromJson(data as Map<String, dynamic>),
    );

    final cachedPhotoPath = await fileService.cacheProfilePhoto(
      apiResponse.data!.profilePhotoUrl,
      apiResponse.data!.userId,
    );

    // Update UserProvider
    userProvider.setUser(
      User(
        userId: apiResponse.data!.userId,
        firstName: apiResponse.data!.firstName,
        lastName: apiResponse.data!.lastName,
        displayName: apiResponse.data!.displayName,
        profilePhotoUrl: cachedPhotoPath,
        userNickname: apiResponse.data!.userNickname,
        userName: apiResponse.data!.userName,
        userRank: apiResponse.data!.userRank
      ),
    );

    await _storage.write(key: 'userId', value: apiResponse.data?.userId);
    await _storage.write(key: 'accessToken', value: apiResponse.data?.accessToken);
    await _storage.write(key: 'refreshToken', value: apiResponse.data?.refreshToken);

    return apiResponse;
  }

  Future<void> signOut(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()),);

    await Future.delayed(const Duration(milliseconds: 100));

    userProvider.clearUser();

    AppNotifier.showMessage("Başarıyla çıkış yapıldı. Tekrar görüşmek üzere...", color: Colors.green);
  }
  
  Future<ApiResponse<AuthenticateResponse>> signInWithGoogle(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final fileService = LocalFileService();
    final GoogleSignInAuthentication googleAuth;
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
        'openid',
      ],
      serverClientId: '719006594337-6sdf908onisvp355mrpls5jecr4ssake.apps.googleusercontent.com', // Buraya web istemci kimliğini girin
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      // Kullanıcı iptal etti
      return new ApiResponse(
          errorCode: 'İşlem iptal edildi!'
      );
    }

    googleAuth = await googleUser.authentication;

    if (googleAuth.idToken != null) {
      final response = await _dio.post('authentication/google-login', data: {
        'idToken': googleAuth.idToken
      });

      var apiResponse = ApiResponse<AuthenticateResponse>.fromJson(
        response.data,
            (data) => AuthenticateResponse.fromJson(data as Map<String, dynamic>),
      );

      final cachedPhotoPath = await fileService.cacheProfilePhoto(
        apiResponse.data!.profilePhotoUrl,
        apiResponse.data!.userId,
      );

      userProvider.setUser(
        User(
          userId: apiResponse.data!.userId,
          firstName: apiResponse.data!.firstName,
          lastName: apiResponse.data!.lastName,
          displayName: apiResponse.data!.displayName,
          profilePhotoUrl: cachedPhotoPath,
          userNickname: apiResponse.data!.userNickname,
          userName: apiResponse.data!.userName,
          userRank: apiResponse.data!.userRank
        ),
      );

      await _storage.write(key: 'userId', value: apiResponse.data?.userId);
      await _storage.write(key: 'accessToken', value: apiResponse.data?.accessToken);
      await _storage.write(key: 'refreshToken', value: apiResponse.data?.refreshToken);

      return apiResponse;
    } else {
      return new ApiResponse(
          errorCode: 'Hata alındı!'
      );
    }
  }
  
  Future<bool> signUp(SignUpRequest request, BuildContext context) async {
    final random = Random().nextInt(5) + 1; // 1..5 arası

    final byteData = await rootBundle.load("assets/ProfilePhotos/photo_$random.png");

    // Geçici klasöre yaz fotoğrafı
    final tempDir = await getTemporaryDirectory();
    final file = File("${tempDir.path}/profilePhoto.png");
    await file.writeAsBytes(byteData.buffer.asUint8List());
    
    FormData formData = FormData.fromMap({
      "firstName": request.firstName,
      "lastName": request.lastName,
      "password": request.password,
      "email": request.email,
      "file": await MultipartFile.fromFile(file.path, filename: "profilePhoto.png"),
      "roles": "Admin",
    });

    final response = await _dio.post("authentication/register", data: formData,
      options: Options(
        contentType: "multipart/form-data",
      ),
    );

    var apiResponse = ApiResponse<SignUpResponse>.fromJson(
      response.data,
          (data) => SignUpResponse.fromJson(data as Map<String, dynamic>),
    );

    if (apiResponse.errorCode != null) {
      return false;
    }

    AppNotifier.showMessage("Kayıt başarıyla oluşturuldu.", color: Colors.green);

    return true;
  }

  Future<bool> isAccessTokenExpired() async {
    return true;
  }

  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    final accessToken = await _storage.read(key: 'accessToken');
    final response = await _dio.post('authentication/refresh', data: {
      'refreshToken': refreshToken,
      'accessToken': accessToken
    });

    var apiResponse = ApiResponse<RefreshTokenResponse>.fromJson(
      response.data,
          (data) => RefreshTokenResponse.fromJson(data as Map<String, dynamic>),
    );

    if (response.statusCode == 200) {
      await _storage.write(key: 'accessToken', value: apiResponse.data?.accessToken);
      return true;
    }

    return false;
  }
}

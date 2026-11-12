import 'dart:convert';
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
import 'package:lingualloop/services/DailyReminders.dart';
import 'package:flutter/cupertino.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';


import '../models/User.dart';
import '../ui/screens/login_screen.dart';

/// Apple'ın giriş penceresini açar; verilen nonce özeti token'a gömülür.
typedef AppleCredentialRequest = Future<AuthorizationCredentialAppleID>
    Function(String hashedNonce);

class AuthService {
  Dio _dio;
  final _storage = const FlutterSecureStorage();
  final AppleCredentialRequest _appleCredential;

  AuthService(this._dio, {AppleCredentialRequest? appleCredential})
      : _appleCredential = appleCredential ?? _requestAppleCredential;

  static Future<AuthorizationCredentialAppleID> _requestAppleCredential(
          String hashedNonce) =>
      SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

  /// Apple'a giden nonce'un açık hâli. Apple özetini token'a gömer, sunucu
  /// açık hâlin özetiyle karşılaştırır: token başka bir girişten alınıp
  /// tekrar kullanılamaz.
  static String _rawNonce() {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  Dio get dio => _dio;

  static const _sessionUserKey = 'sessionUser';

  /// Uygulama açılırken kayıtlı oturumu okur; yoksa `null`.
  ///
  /// İlk ekrandan önce çağrılır ki giriş yapmış kullanıcı karşılama ekranını
  /// hiç görmesin. Token'ın süresine burada bakılmaz: dolmuşsa ilk istekte
  /// `TokenInterceptor` yeniler, oturum bitmişse girişe gönderir.
  static Future<User?> restoreSession({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    LocalFileService? files,
  }) async {
    try {
      final saved = await storage.read(key: _sessionUserKey);
      final refreshToken = await storage.read(key: 'refreshToken');
      if (saved == null || refreshToken == null) return null;

      final user = User.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      // Fotoğrafın tam yolu saklanamaz: iOS uygulama klasörünü güncellemede
      // taşıyor. Yol her açılışta yeniden kurulur.
      user.profilePhotoUrl = await (files ?? LocalFileService())
          .cachedProfilePhotoPath(user.userId);
      return user;
    } catch (_) {
      // Okunamayan kayıt yalnız yeniden girişe yol açar, açılışı engellemez.
      return null;
    }
  }

  Future<void> _saveSession(AuthenticateResponse session, User user) async {
    await _storage.write(key: 'userId', value: session.userId);
    await _storage.write(key: 'accessToken', value: session.accessToken);
    await _storage.write(key: 'refreshToken', value: session.refreshToken);
    await _storage.write(
        key: _sessionUserKey, value: jsonEncode(user.toJson()));
  }

  /// Sonraki açılış karşılama ekranından başlasın diye oturumu siler.
  Future<void> clearSession() async {
    await DailyReminders.cancel();
    for (final key in ['userId', 'accessToken', 'refreshToken', _sessionUserKey]) {
      await _storage.delete(key: key);
    }
  }

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

    if (apiResponse.errorCode != null || apiResponse.data == null) {
      return apiResponse;
    }

    String? cachedPhotoPath;
    try {
      cachedPhotoPath = await fileService.cacheProfilePhoto(
        apiResponse.data!.profilePhotoUrl,
        apiResponse.data!.userId,
      );
    } catch (_) {
      // Profil görseli indirilemese de doğrulanmış giriş tamamlanır.
      // Fotoğraf bileşeni bu durumda varsayılan görselini gösterir.
    }

    final user = User(
      userId: apiResponse.data!.userId,
      firstName: apiResponse.data!.firstName,
      lastName: apiResponse.data!.lastName,
      displayName: apiResponse.data!.displayName,
      profilePhotoUrl: cachedPhotoPath,
      userNickname: apiResponse.data!.userNickname,
      userName: apiResponse.data!.userName,
      userRank: apiResponse.data!.userRank
    );

    // Update UserProvider
    userProvider.setUser(user);
    await _saveSession(apiResponse.data!, user);

    return apiResponse;
  }

  Future<void> signOut(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()),);

    await clearSession();
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

      if (apiResponse.errorCode != null || apiResponse.data == null) {
        return apiResponse;
      }

      String? cachedPhotoPath;
      try {
        cachedPhotoPath = await fileService.cacheProfilePhoto(
          apiResponse.data!.profilePhotoUrl,
          apiResponse.data!.userId,
        );
      } catch (_) {
        // Google oturumu da yalnız profil fotoğrafı için başarısız sayılmaz.
      }

      final user = User(
        userId: apiResponse.data!.userId,
        firstName: apiResponse.data!.firstName,
        lastName: apiResponse.data!.lastName,
        displayName: apiResponse.data!.displayName,
        profilePhotoUrl: cachedPhotoPath,
        userNickname: apiResponse.data!.userNickname,
        userName: apiResponse.data!.userName,
        userRank: apiResponse.data!.userRank
      );

      userProvider.setUser(user);
      await _saveSession(apiResponse.data!, user);

      return apiResponse;
    } else {
      return new ApiResponse(
          errorCode: 'Hata alındı!'
      );
    }
  }

  /// Apple ile giriş. Kimlik token'ını sunucu doğrular; hesap yoksa açar,
  /// aynı e-postayla açılmış hesap varsa ona bağlar. Ad yalnız ilk girişte
  /// gelir, sunucuya o zaman iletilir. Apple fotoğraf vermez.
  Future<ApiResponse<AuthenticateResponse>> signInWithApple(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final fileService = LocalFileService();
    final rawNonce = _rawNonce();

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await _appleCredential(
        sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return ApiResponse(errorCode: 'İşlem iptal edildi!');
      }
      rethrow;
    }

    if (credential.identityToken == null) {
      return ApiResponse(errorCode: 'Hata alındı!');
    }

    final response = await _dio.post('authentication/apple-login', data: {
      'identityToken': credential.identityToken,
      'rawNonce': rawNonce,
      'givenName': credential.givenName,
      'familyName': credential.familyName,
    });

    var apiResponse = ApiResponse<AuthenticateResponse>.fromJson(
      response.data,
      (data) => AuthenticateResponse.fromJson(data as Map<String, dynamic>),
    );

    if (apiResponse.errorCode != null || apiResponse.data == null) {
      return apiResponse;
    }

    // Apple ile açılan hesabın fotoğrafı yok, varsayılan görsel görünür;
    // e-postayla bağlanan eski hesabın fotoğrafı varsa iner.
    String? cachedPhotoPath;
    if (apiResponse.data!.profilePhotoUrl.isNotEmpty) {
      try {
        cachedPhotoPath = await fileService.cacheProfilePhoto(
          apiResponse.data!.profilePhotoUrl,
          apiResponse.data!.userId,
        );
      } catch (_) {
        // Fotoğraf inmese de doğrulanmış giriş tamamlanır.
      }
    }

    final user = User(
      userId: apiResponse.data!.userId,
      firstName: apiResponse.data!.firstName,
      lastName: apiResponse.data!.lastName,
      displayName: apiResponse.data!.displayName,
      profilePhotoUrl: cachedPhotoPath,
      userNickname: apiResponse.data!.userNickname,
      userName: apiResponse.data!.userName,
      userRank: apiResponse.data!.userRank,
    );

    userProvider.setUser(user);
    await _saveSession(apiResponse.data!, user);

    return apiResponse;
  }

  Future<ApiResponse<Map<String, dynamic>>> signUp(SignUpRequest request, BuildContext context) async {
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
      "roles": "User",
    });

    final response = await _dio.post("authentication/register", data: formData,
      options: Options(
        contentType: "multipart/form-data",
      ),
    );

    return ApiResponse<Map<String, dynamic>>.fromJson(
      response.data,
          (data) => data as Map<String, dynamic>,
    );
  }

  Future<bool> isAccessTokenExpired() async {
    return true;
  }

  /// Süren yenileme. Anahtarın süresi dolunca aynı anda giden istekler
  /// birlikte reddedilir; her biri kendi yenilemesini başlatıyordu (soğuk
  /// açılışta iki ayrı ~1,9 sn'lik yenileme). Artık hepsi bunu bekler.
  Future<bool>? _refreshing;

  Future<bool> refreshToken() =>
      _refreshing ??= _refreshToken().whenComplete(() => _refreshing = null);

  Future<bool> _refreshToken() async {
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

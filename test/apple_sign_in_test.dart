import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Gelen isteği saklar, Apple ile açılmış (fotoğrafsız) bir oturum döner.
class _Server implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({
        'data': {
          'userId': 'apple-user',
          'firstName': 'Ada',
          'lastName': 'Yılmaz',
          'displayName': 'Ada Yılmaz',
          'profilePhotoUrl': '',
          'userNickname': 'adayilmaz',
          'userName': 'adayilmaz',
          'userRank': 1,
          'accessToken': 'erisim',
          'refreshToken': 'yenileme',
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AuthorizationCredentialAppleID _credential() => const AuthorizationCredentialAppleID(
      userIdentifier: '001234.abcd',
      givenName: 'Ada',
      familyName: 'Yılmaz',
      authorizationCode: 'kod',
      email: 'ada@ornek.com',
      identityToken: 'apple-kimlik-token',
      state: null,
    );

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<BuildContext> contextWith(
      WidgetTester tester, UserProvider users) async {
    late BuildContext context;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: users,
      child: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }),
    ));
    return context;
  }

  testWidgets('Apple kimliği nonce ile sunucuya gider, oturum açılır',
      (tester) async {
    final server = _Server();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/ll-api/'))
      ..httpClientAdapter = server;
    String? nonceToApple;
    final auth = AuthService(dio, appleCredential: (hashedNonce) async {
      nonceToApple = hashedNonce;
      return _credential();
    });
    final users = UserProvider();
    final context = await contextWith(tester, users);

    final response =
        await tester.runAsync(() => auth.signInWithApple(context));

    expect(response!.errorCode, isNull);
    final request = server.requests.single;
    expect(request.path, 'authentication/apple-login');
    final body = request.data as Map<String, dynamic>;
    expect(body['identityToken'], 'apple-kimlik-token');
    expect(body['givenName'], 'Ada');
    expect(body['familyName'], 'Yılmaz');
    // Apple'a açık değerin özeti gider, sunucuya açık değer: sunucu ikisini
    // karşılaştırır.
    final rawNonce = body['rawNonce'] as String;
    expect(rawNonce, hasLength(32));
    expect(sha256.convert(utf8.encode(rawNonce)).toString(), nonceToApple);

    expect(users.user!.userId, 'apple-user');
    expect(users.user!.profilePhotoUrl, isNull);
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'accessToken'), 'erisim');
    expect(await storage.read(key: 'refreshToken'), 'yenileme');
    expect(await storage.read(key: 'sessionUser'), contains('apple-user'));
  });

  testWidgets('Apple penceresi kapatılınca sunucuya gidilmez', (tester) async {
    final server = _Server();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/ll-api/'))
      ..httpClientAdapter = server;
    final auth = AuthService(dio,
        appleCredential: (_) async => throw const SignInWithAppleAuthorizationException(
              code: AuthorizationErrorCode.canceled,
              message: 'iptal',
            ));
    final context = await contextWith(tester, UserProvider());

    final response =
        await tester.runAsync(() => auth.signInWithApple(context));

    expect(response!.errorCode, 'İşlem iptal edildi!');
    expect(server.requests, isEmpty);
    expect(await const FlutterSecureStorage().read(key: 'accessToken'), isNull);
  });
}

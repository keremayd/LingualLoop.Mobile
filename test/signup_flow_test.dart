import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/Requests/SignUpRequest.dart';
import 'package:lingualloop/models/responses/AuthenticateResponse.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/ui/screens/SignUpScreen.dart';
import 'package:provider/provider.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());

  final registrations = <SignUpRequest>[];
  final logins = <(String, String)>[];
  Completer<ApiResponse<Map<String, dynamic>>> registration = Completer();
  Completer<ApiResponse<AuthenticateResponse>> login = Completer();

  @override
  Future<ApiResponse<Map<String, dynamic>>> signUp(
      SignUpRequest request, BuildContext context) {
    registrations.add(request);
    return registration.future;
  }

  @override
  Future<ApiResponse<AuthenticateResponse>> signIn(
      String email, String password, BuildContext context) {
    logins.add((email, password));
    return login.future;
  }
}

void main() {
  Future<void> showSignUp(WidgetTester tester, _FakeAuthService auth) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      Provider<AuthService>.value(
        value: auth,
        child: MaterialApp(
          home: SignUpScreen(),
          routes: {'/home': (_) => const Scaffold(body: Text('Ana ekran'))},
        ),
      ),
    );
  }

  Future<void> fillForm(WidgetTester tester,
      {String email = 'ben@ornek.com', String password = 'sifre123'}) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '  Ada  ');
    await tester.enterText(fields.at(1), '  Yılmaz  ');
    await tester.enterText(fields.at(2), email);
    await tester.enterText(fields.at(3), password);
  }

  ApiResponse<AuthenticateResponse> loggedIn() => ApiResponse(
        data: AuthenticateResponse(
          userId: 'new-user',
          firstName: 'Ada',
          lastName: 'Yılmaz',
          displayName: 'Ada Yılmaz',
          profilePhotoUrl: '',
          userNickname: 'ada',
          userName: 'ada',
          userRank: 1,
          accessToken: 'test-token',
          refreshToken: 'test-refresh',
        ),
      );

  testWidgets('alan hataları temizlenir, geçerli form bir kez gönderilir',
      (tester) async {
    final auth = _FakeAuthService();
    await showSignUp(tester, auth);

    await tester.tap(find.text('Kayıt ol'));
    await tester.pump();
    expect(find.text('İsmini yazmalısın.'), findsOneWidget);
    expect(auth.registrations, isEmpty);

    await fillForm(tester, password: 'sifrem');
    await tester.tap(find.text('Kayıt ol'));
    await tester.pump();
    expect(find.text('Şifren en az 6 karakter ve bir rakam içermeli.'),
        findsOneWidget);
    expect(auth.registrations, isEmpty);

    await tester.enterText(find.byType(TextField).at(3), 'sifre123');
    await tester.pump();
    expect(find.text('Şifren en az 6 karakter ve bir rakam içermeli.'),
        findsNothing);

    await tester.tap(find.text('Kayıt ol'));
    await tester.pump();
    expect(auth.registrations, hasLength(1));
    expect(auth.registrations.single.firstName, 'Ada');
    expect(auth.registrations.single.lastName, 'Yılmaz');
    expect(auth.registrations.single.email, 'ben@ornek.com');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(CircularProgressIndicator));
    await tester.pump();
    expect(auth.registrations, hasLength(1));

    auth.registration
        .complete(ApiResponse(data: {'user': <String, dynamic>{}}));
    await tester.pump();
    expect(auth.logins, [('ben@ornek.com', 'sifre123')]);
    auth.login.complete(loggedIn());
    await tester.pumpAndSettle();
    expect(find.text('Ana ekran'), findsOneWidget);
  });

  testWidgets('tekrarlanan e-posta alanı işaretlenir, düzeltme yeni istek açar',
      (tester) async {
    final auth = _FakeAuthService();
    await showSignUp(tester, auth);
    await fillForm(tester);
    await tester.tap(find.text('Kayıt ol'));
    await tester.pump();

    final options = RequestOptions(path: 'authentication/register');
    auth.registration.completeError(DioError(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 400,
        data: {
          'errorList': {
            'errorCode': ['DuplicateEmail'],
          },
        },
      ),
      type: DioErrorType.response,
    ));
    await tester.pumpAndSettle();
    expect(
        find.text('Bu e-posta adresiyle zaten bir hesap var.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(2), 'yeni@ornek.com');
    await tester.pump();
    expect(
        find.text('Bu e-posta adresiyle zaten bir hesap var.'), findsNothing);

    auth.registration = Completer();
    await tester.tap(find.text('Kayıt ol'));
    await tester.pump();
    expect(auth.registrations, hasLength(2));
    expect(auth.registrations.last.email, 'yeni@ornek.com');
    auth.registration.complete(ApiResponse(errorCode: 'Rejected'));
    await tester.pumpAndSettle();
    expect(find.text('Şu anda kayıt oluşturulamıyor. Lütfen tekrar dene.'),
        findsOneWidget);
  });

  testWidgets('kayıt sonrası giriş hatasında hesap tekrar oluşturulmaz',
      (tester) async {
    final auth = _FakeAuthService();
    await showSignUp(tester, auth);
    await fillForm(tester);
    await tester.tap(find.text('Kayıt ol'));
    await tester.pump();
    auth.registration
        .complete(ApiResponse(data: {'user': <String, dynamic>{}}));
    await tester.pump();

    auth.login.complete(ApiResponse(errorCode: 'LoginFailed'));
    await tester.pumpAndSettle();
    expect(find.text('Hesabın oluşturuldu. Giriş yapılamadı; tekrar dene.'),
        findsOneWidget);
    expect(find.text('Giriş yap'), findsWidgets);

    auth.login = Completer();
    await tester.tap(find.text('Giriş yap').first);
    await tester.pump();
    expect(auth.registrations, hasLength(1));
    expect(auth.logins, hasLength(2));
    auth.login.complete(loggedIn());
    await tester.pumpAndSettle();
    expect(find.text('Ana ekran'), findsOneWidget);
  });

  testWidgets('bağlantı hatası gösterilir ve kayıt yeniden denenir',
      (tester) async {
    final auth = _FakeAuthService();
    await showSignUp(tester, auth);
    await fillForm(tester);
    await tester.tap(find.text('Kayıt ol'));
    await tester.pump();

    auth.registration.completeError(DioError(
      requestOptions: RequestOptions(path: 'authentication/register'),
      type: DioErrorType.other,
    ));
    await tester.pumpAndSettle();
    expect(
      find.text('Bağlantı kurulamadı. İnternetini ve sunucuyu kontrol et.'),
      findsOneWidget,
    );

    auth.registration = Completer();
    await tester.tap(find.text('Kayıt ol'));
    await tester.pump();
    expect(auth.registrations, hasLength(2));
    auth.registration.complete(ApiResponse(errorCode: 'Rejected'));
    await tester.pumpAndSettle();
  });
}

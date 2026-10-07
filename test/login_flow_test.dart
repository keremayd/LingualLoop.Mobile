import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/models/ApiResponse.dart';
import 'package:lingualloop/models/responses/AuthenticateResponse.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/screens/login_screen.dart';
import 'package:provider/provider.dart';

class _LoginRequest {
  const _LoginRequest(this.email, this.password);
  final String email;
  final String password;
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());

  final requests = <_LoginRequest>[];
  Completer<ApiResponse<AuthenticateResponse>> pending = Completer();

  @override
  Future<ApiResponse<AuthenticateResponse>> signIn(
      String email, String password, BuildContext context) {
    requests.add(_LoginRequest(email, password));
    return pending.future;
  }
}

void main() {
  Future<void> showLogin(WidgetTester tester, _FakeAuthService auth) async {
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
          home: LoginScreen(),
          routes: {'/home': (_) => const Scaffold(body: Text('Ana ekran'))},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('form doğrulanır ve girilen bilgilerle tek istek gönderilir',
      (tester) async {
    final auth = _FakeAuthService();
    await showLogin(tester, auth);

    await tester.tap(find.text('Giriş yap'));
    await tester.pump();
    expect(auth.requests, isEmpty);
    expect(find.text('E-posta adresini gir.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'gecersiz');
    await tester.tap(find.text('Giriş yap'));
    await tester.pump();
    expect(auth.requests, isEmpty);
    expect(find.text('Geçerli bir e-posta adresi gir.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ben@ornek.com');
    await tester.tap(find.text('Giriş yap'));
    await tester.pump();
    expect(auth.requests, isEmpty);
    expect(find.text('Şifreni gir.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'gizli-sifre');
    await tester.tap(find.text('Giriş yap'));
    await tester.pump();

    expect(auth.requests, hasLength(1));
    expect(auth.requests.single.email, 'ben@ornek.com');
    expect(auth.requests.single.password, 'gizli-sifre');
    expect(find.text('Giriş yapılıyor...'), findsOneWidget);
    await tester.tap(find.byType(DepthPressableButton).last);
    await tester.pump();
    expect(auth.requests, hasLength(1));

    auth.pending.complete(ApiResponse(errorCode: 'TheUserAuthenticatedFailed'));
    await tester.pumpAndSettle();
    expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);
    expect(find.text('Giriş yap'), findsOneWidget);
  });

  testWidgets('test girişi formu doldurmadan hesabı açar', (tester) async {
    final auth = _FakeAuthService();
    await showLogin(tester, auth);

    await tester.tap(find.text('TEST GİRİŞİ'));
    await tester.pump();
    expect(auth.requests, hasLength(1));
    expect(auth.requests.single.email, 'sefa@gmail.com');
    expect(auth.requests.single.password, 'sefa123');

    auth.pending.complete(ApiResponse(
        data: AuthenticateResponse(
      userId: 'test-user',
      firstName: 'Test',
      lastName: 'User',
      displayName: 'Test User',
      profilePhotoUrl: '',
      userNickname: 'test',
      userName: 'test',
      userRank: 1,
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
    )));
    await tester.pumpAndSettle();
    expect(find.text('Ana ekran'), findsOneWidget);
  });

  testWidgets('401 ve bağlantı hatası ekranda kalır, tekrar denenebilir',
      (tester) async {
    final auth = _FakeAuthService();
    await showLogin(tester, auth);

    await tester.tap(find.text('TEST GİRİŞİ'));
    await tester.pump();
    final options = RequestOptions(path: 'authentication/login');
    auth.pending.completeError(DioError(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 401),
      type: DioErrorType.response,
    ));
    await tester.pumpAndSettle();
    expect(find.text('E-posta veya şifre hatalı.'), findsOneWidget);

    auth.pending = Completer();
    await tester.tap(find.text('TEST GİRİŞİ'));
    await tester.pump();
    auth.pending.completeError(DioError(
      requestOptions: options,
      type: DioErrorType.other,
    ));
    await tester.pumpAndSettle();
    expect(
      find.text('Bağlantı kurulamadı. İnternetini ve sunucuyu kontrol et.'),
      findsOneWidget,
    );
    expect(auth.requests, hasLength(2));
  });
}

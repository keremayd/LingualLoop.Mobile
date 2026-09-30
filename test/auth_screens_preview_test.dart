import 'helpers/preview_fonts.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/ui/screens/SignUpScreen.dart';
import 'package:lingualloop/ui/screens/login_screen.dart';
import 'package:provider/provider.dart';

/// Giriş ve kayıt ekranları yan yana — gerçek cihaz ölçüsünde (430×932).
///
///   flutter test --update-goldens test/auth_screens_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  Future<void> shoot(WidgetTester tester, Widget screen, String name) async {
    const size = Size(430, 932);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      Provider<AuthService>(
        create: (_) => AuthService(Dio()),
        child: MaterialApp(debugShowCheckedModeBanner: false, home: screen),
      ),
    );
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pump();

    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets(
      'giris ekrani', (t) async => shoot(t, LoginScreen(), 'auth_login'));
  testWidgets(
      'kayit ekrani', (t) async => shoot(t, SignUpScreen(), 'auth_signup'));
}

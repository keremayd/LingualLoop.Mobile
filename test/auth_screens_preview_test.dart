import 'helpers/preview_fonts.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/ui/screens/SignUpScreen.dart';
import 'package:lingualloop/ui/screens/login_screen.dart';
import 'package:lingualloop/ui/widgets/Buttons/auth_back_button.dart';
import 'package:provider/provider.dart';

/// Giriş ve kayıt ekranları yan yana — gerçek cihaz ölçüsünde (430×932).
///
///   flutter test --update-goldens test/auth_screens_preview_test.dart
void main() {
  setUpAll(loadPreviewFonts);

  Future<void> shoot(WidgetTester tester, Widget screen, String name,
      {bool submitEmptyForm = false}) async {
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
    if (submitEmptyForm) {
      await tester.tap(find.text('Kayıt ol'));
      await tester.pump();
    }

    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets(
      'giris ekrani', (t) async => shoot(t, LoginScreen(), 'auth_login'));
  testWidgets(
      'kayit ekrani', (t) async => shoot(t, SignUpScreen(), 'auth_signup'));
  testWidgets(
    'kayit hata gorunumu',
    (t) async =>
        shoot(t, SignUpScreen(), 'auth_signup_error', submitEmptyForm: true),
  );

  testWidgets('geri düğmesi başlık alanında kırpılmaz', (tester) async {
    for (final width in [320.0, 430.0]) {
      final size = Size(width, 932);
      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      for (final screen in [LoginScreen(), SignUpScreen()]) {
        await tester.pumpWidget(
          Provider<AuthService>(
            create: (_) => AuthService(Dio()),
            child: MaterialApp(home: screen),
          ),
        );

        final back = tester.getRect(find.byType(AuthBackButton));
        final header = find
            .ancestor(
              of: find.byType(AuthBackButton),
              matching: find.byType(Stack),
            )
            .evaluate()
            .map((element) => element.renderObject)
            .whereType<RenderBox>()
            .map((box) => box.localToGlobal(Offset.zero) & box.size)
            .reduce((a, b) => a.height < b.height ? a : b);

        expect(back.top, greaterThanOrEqualTo(header.top));
        expect(back.bottom, lessThanOrEqualTo(header.bottom));
      }
    }
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stelinda/ui/widgets/password_help_sheet.dart';
import 'package:stelinda/ui/widgets/settings_sheet.dart';

import 'helpers/preview_fonts.dart';

/// Girişteki şifre penceresi ve premium üyenin hesap silme onayı.
///
/// Normal koşuda 375 ve 430 genişlikte taşma denetlenir.
/// `PASSWORD_HELP_CAPTURE=true` iki pencereyi yan yana golden olarak çizer.
final _capture = Platform.environment['PASSWORD_HELP_CAPTURE'] == 'true';

const _phone = Size(402, 874);

Widget _sheet() => Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF041227)),
        ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
        Align(
          alignment: Alignment.bottomCenter,
          child: PasswordHelpSheetPanel(onWrite: () {}, onClose: () {}),
        ),
      ],
    );

Widget _deletion() => Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF041227)),
        Material(
          type: MaterialType.transparency,
          child: Center(
            child: AccountDeletionCard(
              onConfirm: () {},
              onCancel: () {},
              onManageSubscription: () {},
            ),
          ),
        ),
      ],
    );

void main() {
  setUpAll(loadPreviewFonts);

  for (final width in [375.0, 430.0]) {
    testWidgets(
        'Şifre penceresi ve abonelik uyarılı silme onayı $width '
        'genişlikte taşmaz', (tester) async {
      tester.view.physicalSize = Size(width, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final screen in [_sheet(), _deletion()]) {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Önizleme: şifre penceresi ve abonelik uyarılı silme onayı',
      (tester) async {
    const gap = 24.0;
    tester.view.physicalSize =
        Size((_phone.width * 2 + gap) * 2, _phone.height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    Widget phone(Widget child) => SizedBox.fromSize(
          size: _phone,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: MediaQuery(
              data: const MediaQueryData(size: _phone),
              child: child,
            ),
          ),
        );

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: const Color(0xFF02091A),
        child: Center(
          child: RepaintBoundary(
            key: const ValueKey('password-help-preview'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                phone(_sheet()),
                const SizedBox(width: gap),
                phone(_deletion()),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byKey(const ValueKey('password-help-preview')),
      matchesGoldenFile('goldens/password_help_preview.png'),
    );
  }, skip: !_capture);
}

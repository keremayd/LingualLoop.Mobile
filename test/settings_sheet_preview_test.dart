import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/screens/legal_document_screen.dart';
import 'package:lingualloop/ui/widgets/settings_sheet.dart';

import 'helpers/preview_fonts.dart';

/// Ayarlar penceresi, hesap silme onayı ve yasal metin sayfası.
///
/// Normal koşuda 375 ve 430 genişlikte taşma ve dokunuşlar denetlenir.
/// `SETTINGS_CAPTURE=true` golden üretir; `SETTINGS_BACKDROP=<yerel PNG>`
/// verilirse arkada gerçek profil ekranının görüntüsü durur.
final _capture = Platform.environment['SETTINGS_CAPTURE'] == 'true';
final _backdrop = Platform.environment['SETTINGS_BACKDROP'];

const _phone = Size(402, 874);

class _Settings {
  final muted = ValueNotifier(false);
  final vibration = ValueNotifier(true);
  final chosen = <SettingsAction>[];

  SettingsSheetPanel panel({String? version}) => SettingsSheetPanel(
        soundMuted: muted,
        onSoundMuted: (value) => muted.value = value,
        vibrationOn: vibration,
        onVibration: (value) => vibration.value = value,
        onSelected: chosen.add,
        version: version,
      );
}

void main() {
  setUpAll(loadPreviewFonts);

  for (final width in [375.0, 430.0]) {
    testWidgets('Ayarlar penceresi $width genişlikte sığar, seçimi bildirir',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final settings = _Settings();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF041227),
          body: Align(
            alignment: Alignment.bottomCenter,
            child: settings.panel(version: 'Sürüm 1.0.0 (1)'),
          ),
        ),
      ));
      expect(find.text('Sürüm 1.0.0 (1)'), findsOneWidget);
      for (final label in [
        'Kullanım koşulları',
        'Gizlilik politikası',
        'Çıkış yap',
        'Hesabı sil',
      ]) {
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(settings.chosen, SettingsAction.values);

      // Anahtarlar pencereyi kapatmaz; ses "sessiz" diye tutulur.
      await tester.tap(find.text('Ses'));
      await tester.tap(find.text('Titreşim'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(settings.muted.value, isTrue);
      expect(settings.vibration.value, isFalse);
      expect(settings.chosen, hasLength(4));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Silme onayı: başarıda true döner, hatada açık kalır',
      (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final answers = <Future<bool> Function()>[
      () async => false,
      () async => throw const SocketException('yok'),
      () async => true,
    ];
    var calls = 0;
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => result = await confirmAccountDeletion(
              context,
              delete: () => answers[calls++](),
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('aç'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('HESABIMI SİL'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Hesap silinemedi. Tekrar dene.'), findsOneWidget);

    await tester.tap(find.text('HESABIMI SİL'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text('Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.'),
      findsOneWidget,
    );
    expect(result, isNull);

    await tester.tap(find.text('HESABIMI SİL'));
    // İlk kare kapanış animasyonunu başlatır, ikincisi bitirir.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(result, isTrue);
    expect(find.byType(AccountDeletionCard), findsNothing);
    expect(calls, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vazgeç false döner, istek yoldayken pencere kapanmaz',
      (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pending = <Future<bool>>[];
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => result = await confirmAccountDeletion(
              context,
              delete: () => pending.isEmpty
                  ? (pending..add(Future.delayed(const Duration(seconds: 1),
                          () => false)))
                      .first
                  : Future.value(false),
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('aç'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('HESABIMI SİL'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Vazgeç'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(AccountDeletionCard), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Vazgeç'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(result, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final document in LegalDocument.values) {
    testWidgets('${document.title} metni okunur ve taşmadan çizilir',
        (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: LegalDocumentScreen(document: document)),
      );
      await tester.runAsync(() => Future<void>.delayed(
            const Duration(milliseconds: 50),
          ));
      await tester.pump();
      expect(find.text(document.title), findsOneWidget);
      expect(find.textContaining('Son güncelleme'), findsOneWidget);
      expect(find.text('•'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Önizleme: ayarlar penceresi, silme onayı ve gizlilik metni',
      (tester) async {
    const gap = 24.0;
    tester.view.physicalSize =
        Size((_phone.width * 3 + gap * 2) * 2, _phone.height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final backdrop = _backdrop == null
        ? null
        : MemoryImage(File(_backdrop!).readAsBytesSync());
    final privacy = File('assets/legal/gizlilik_politikasi.md').readAsStringSync();

    Widget phone(Widget overlay, {bool backdropBehind = true}) =>
        SizedBox.fromSize(
          size: _phone,
          child: ClipRect(
            child: MediaQuery(
              data: const MediaQueryData(
                size: _phone,
                devicePixelRatio: 2,
                padding: EdgeInsets.only(top: 62, bottom: 34),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (backdrop != null && backdropBehind)
                    Image(image: backdrop, fit: BoxFit.cover)
                  else
                    const ColoredBox(color: Color(0xFF041227)),
                  overlay,
                ],
              ),
            ),
          ),
        );

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: Colors.black,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: const ValueKey('settings-preview'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                phone(Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _Settings().panel(version: 'Sürüm 1.0.0 (1)'),
                    ),
                  ],
                )),
                const SizedBox(width: gap),
                phone(Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: const Color(0xFF041227).withValues(alpha: 0.86),
                    ),
                    // Uygulamada kartı `Dialog` taşıyor; onun Material'ı
                    // olmadan yazılar hata çizgisiyle çiziliyor.
                    Material(
                      type: MaterialType.transparency,
                      child: Center(
                        child: AccountDeletionCard(
                          onConfirm: () {},
                          onCancel: () {},
                        ),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: gap),
                phone(
                  LegalDocumentScreen(
                    document: LegalDocument.privacy,
                    text: privacy,
                  ),
                  backdropBehind: false,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byKey(const ValueKey('settings-preview')),
      matchesGoldenFile('goldens/settings_sheet_preview.png'),
    );
  }, skip: !_capture);
}

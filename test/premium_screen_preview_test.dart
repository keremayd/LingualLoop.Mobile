import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/screens/premium_screen.dart';

import 'helpers/preview_fonts.dart';

/// Premium akışı: önce Ücretsiz/Premium tablosu, sonra plan seçimi.
///
/// Normal koşuda küçük ekranda taşma, adım geçişleri ve dokunuşlar
/// denetlenir. `PREMIUM_CAPTURE=true` golden üretir: solda tablo adımı,
/// sağda plan adımı (yıllık seçili). Fiyatlar örnek.
final _capture = Platform.environment['PREMIUM_CAPTURE'] == 'true';

const _offer = PremiumOffer(
  yearlyPrice: '899,99 TL',
  yearlyPerMonth: '75 TL',
  monthlyPrice: '149,99 TL',
  yearlySavingPercent: 50,
);

const _phone = Size(402, 874);

// Mağaza cümlesi platforma göre; önizleme iPhone'u gösteriyor.
final _ios = ThemeData(platform: TargetPlatform.iOS);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('Küçük ekranda iki adım sığar; geri hareketi tabloya döner',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bought = <PremiumPlan>[];
    final links = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: _ios,
      home: PremiumScreen(
        offer: _offer,
        onPurchase: bought.add,
        onRestore: () => links.add('geri yükle'),
        onTerms: () => links.add('koşullar'),
        onPrivacy: () => links.add('gizlilik'),
        onClose: () => links.add('kapat'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    // Tablo adımı: öğrenme içeriği iki tarafta da var, fiyat henüz yok.
    expect(find.text('Tüm öğrenme içeriği'), findsOneWidget);
    expect(find.textContaining('899,99'), findsNothing);
    await tester.tap(find.text('DEVAM ET'));
    await _settle(tester);

    expect(find.text('Tüm öğrenme içeriği'), findsNothing);
    expect(find.text('App Store üzerinden her zaman iptal edilebilir.'),
        findsOneWidget);
    expect(
        find.textContaining('ardından yıllık 899,99\u00A0TL'), findsOneWidget);
    await tester.tap(find.text('7 GÜN ÜCRETSİZ DENE'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text('Aylık'));
    await tester.tap(find.text('Aylık'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        find.textContaining('ardından aylık 149,99\u00A0TL'), findsOneWidget);
    await tester.tap(find.text('7 GÜN ÜCRETSİZ DENE'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(bought, [PremiumPlan.yearly, PremiumPlan.monthly]);

    for (final label in [
      'Geri yükle',
      'Kullanım koşulları',
      'Gizlilik politikası'
    ]) {
      await tester.tap(find.text(label));
    }

    // Sistem geri hareketi rotayı kapatmaz, tabloya döner.
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text('DEVAM ET'), findsOneWidget);

    // Ekrandaki geri düğmesi de aynı yere döner.
    await tester.tap(find.text('DEVAM ET'));
    await _settle(tester);
    await tester.tap(find.bySemanticsLabel('Geri'));
    await _settle(tester);
    expect(find.text('Tüm öğrenme içeriği'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Kapat'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(links, ['geri yükle', 'koşullar', 'gizlilik', 'kapat']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seriden gelince tabloda koruma biletten önce', (tester) async {
    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: PremiumScreen(
        offer: _offer,
        entry: PremiumEntry.streak,
        onPurchase: (_) {},
        onRestore: () {},
        onTerms: () {},
        onPrivacy: () {},
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    final content = tester.getTopLeft(find.text('Tüm öğrenme içeriği'));
    final freeze = tester.getTopLeft(find.text('Haftada 2 seri koruması'));
    final tickets = tester.getTopLeft(find.text('Sınırsız bilet'));
    expect(content.dy, lessThan(freeze.dy));
    expect(freeze.dy, lessThan(tickets.dy));
  });

  testWidgets('Önizleme: tablo ve plan adımı', (tester) async {
    const gap = 24.0;
    tester.view.physicalSize =
        Size((_phone.width * 2 + gap) * 2, _phone.height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    Widget phone(Widget child) => SizedBox.fromSize(
          size: _phone,
          child: ClipRect(
            child: MediaQuery(
              data: const MediaQueryData(
                size: _phone,
                devicePixelRatio: 2,
                padding: EdgeInsets.only(top: 62, bottom: 34),
              ),
              child: child,
            ),
          ),
        );

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _ios,
      home: ColoredBox(
        color: Colors.black,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: const ValueKey('premium-preview'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                phone(PremiumScreen(
                  offer: _offer,
                  onPurchase: (_) {},
                  onRestore: () {},
                  onTerms: () {},
                  onPrivacy: () {},
                )),
                const SizedBox(width: gap),
                phone(PremiumScreen(
                  offer: _offer,
                  initialStep: PremiumStep.plans,
                  onPurchase: (_) {},
                  onRestore: () {},
                  onTerms: () {},
                  onPrivacy: () {},
                )),
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
      find.byKey(const ValueKey('premium-preview')),
      matchesGoldenFile('goldens/premium_screen_preview.png'),
    );
  }, skip: !_capture);
}

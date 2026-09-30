import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Giriş kutusu ölçüleri — mevcut hâl ile sıkılaştırılmış hâller yan yana.
///
/// Gerçek cihaz genişliğinde (430px); karar oranlarda değil **cihazdaki
/// punto ve yükseklikte** veriliyor.
///
///   flutter test --update-goldens test/login_input_scale_test.dart
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Inter');
    loader.addFont(Future.value(ByteData.view(File(
      '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile'
      '/assets/fonts/Inter-SemiBold.ttf',
    ).readAsBytesSync().buffer)));
    await loader.load();
  });

  testWidgets('giris kutusu olcekleri', (tester) async {
    const size = Size(430, 700);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF041227),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Group(
                    title: 'ŞU AN — 83pt yüksek, r26, kontur 4, metin 20',
                    height: 83, radius: 26, border: 4, font: 20),
                SizedBox(height: 22),
                _Group(
                    title: 'SIKILAŞTIRILMIŞ — 64pt, r15, kontur 2, metin 17',
                    height: 64, radius: 15, border: 2, font: 17),
                SizedBox(height: 22),
                _Group(
                    title: 'DAHA DA — 55pt, r12, kontur 1.5, metin 16',
                    height: 55, radius: 12, border: 1.5, font: 16),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 40));

    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/login_input_scale.png'));
  });
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.height,
    required this.radius,
    required this.border,
    required this.font,
  });

  final String title;
  final double height, radius, border, font;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFF5C6C80),
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        _Field(
            text: 'E-posta',
            muted: true,
            height: height,
            radius: radius,
            border: border,
            font: font),
        const SizedBox(height: 9),
        _Field(
            text: 'kerem@ornek.com',
            muted: false,
            height: height,
            radius: radius,
            border: border,
            font: font),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.text,
    required this.muted,
    required this.height,
    required this.radius,
    required this.border,
    required this.font,
  });

  final String text;
  final bool muted;
  final double height, radius, border, font;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0C2244),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF163258), width: border),
      ),
      padding: EdgeInsets.symmetric(horizontal: radius + 6),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: muted ? const Color(0xFF8FA0B5) : Colors.white,
          fontFamily: 'Inter',
          fontSize: font,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

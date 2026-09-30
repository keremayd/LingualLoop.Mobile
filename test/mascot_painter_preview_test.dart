import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/mascot_mark.dart';

/// Kodla çizilen maskot — beş poz, iki boyutta.
///
/// Renkler üretilmiş görselden örneklendi. Bu önizleme "painter ile bu
/// karakter ne kadar yaklaşabiliyor" sorusunu somut olarak cevaplıyor;
/// kararı tartışmayla değil kareyle vermek için.
///
///   flutter test --update-goldens test/mascot_painter_preview_test.dart
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Inter');
    final bytes = File(
      '/Users/kerem.aydin/Desktop/Repos/Lingualloop/LingualLoop.Mobile'
      '/assets/fonts/Inter-SemiBold.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  testWidgets('maskot pozlari', (tester) async {
    const size = Size(1100, 620);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    const poses = <MascotPose, String>{
      MascotPose.idle: 'idle — seri 0',
      MascotPose.wave: 'wave — gün kapandı',
      MascotPose.flex: 'flex — kararlılık',
      MascotPose.cheer: 'cheer — kilometre taşı',
      MascotPose.sad: 'sad — seri kırıldı',
    };

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF041227),
          body: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BÜYÜK — 190px',
                    style: TextStyle(
                        color: Color(0xFF5C6C80),
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final e in poses.entries)
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 190,
                              child: MascotMark(size: 190, pose: e.key),
                            ),
                            const SizedBox(height: 6),
                            Text(e.value,
                                style: const TextStyle(
                                    color: Color(0xFF8FA0B5),
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text('GERÇEK BOYUT — 115pt',
                    style: TextStyle(
                        color: Color(0xFF5C6C80),
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final e in poses.entries)
                      Expanded(
                        child: SizedBox(
                          height: 115,
                          child: MascotMark(size: 115, pose: e.key),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text('ŞİMŞEK',
                    style: TextStyle(
                        color: Color(0xFF5C6C80),
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8)),
                const SizedBox(height: 8),
                const MascotBolt(size: 150),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/mascot_painter.png'),
    );
  });
}

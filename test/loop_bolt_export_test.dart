import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/mascot_mark.dart';

/// Loop şimşeğini tek başına, büyük ve koyu lacivert zeminde dışa aktarır.
///
/// Görsel üretim modeline **referans olarak** verilecek: şimşek kodda painter
/// olarak var (`_BoltPainter`), modelin uydurduğu standart ⚡ formu bizim
/// işaretimiz değil.
///
///   flutter test --update-goldens test/loop_bolt_export_test.dart
void main() {
  testWidgets('loop simsegi', (tester) async {
    const size = Size(900, 900);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF041227),
          body: Center(child: MascotBolt(size: 640)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 40));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/loop_bolt.png'),
    );
  });
}

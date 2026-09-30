import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/karty_success_celebration.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(File('assets/fonts/Inter-SemiBold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  });

  testWidgets('puan aktarımı accent boost dilini kullanır', (tester) async {
    const size = Size(750, 500);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _TransferPreview());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 330));

    await expectLater(
      find.byType(_TransferPreview),
      matchesGoldenFile('goldens/karty_score_transfer.png'),
    );
  });
}

class _TransferPreview extends StatefulWidget {
  const _TransferPreview();

  @override
  State<_TransferPreview> createState() => _TransferPreviewState();
}

class _TransferPreviewState extends State<_TransferPreview> {
  final _key = GlobalKey<KartySuccessCelebrationState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _key.currentState?.play(streak: 4, awardedPoints: 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF041227),
        body: Stack(
          children: [
            const Positioned(
              left: 45,
              top: 230,
              child: Text(
                'Doğru cevap: yerel yeşil onay',
                style: TextStyle(
                  color: Color(0xFF93D334),
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Positioned(
              right: 55,
              top: 80,
              child: Text(
                'LİG  128',
                style: TextStyle(
                  color: Color(0xFFE9EEF5),
                  fontFamily: 'Inter',
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned.fill(
              child: KartySuccessCelebration(key: _key, scale: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

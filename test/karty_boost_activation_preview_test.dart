import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/karty_boost_activation_effect.dart';
import 'package:lingualloop/ui/widgets/karty_boost_edge_meter.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(File('assets/fonts/Inter-SemiBold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  });

  testWidgets('boost açılışı kaynak çarpma ve sönme sırası', (tester) async {
    const size = Size(1080, 700);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _Preview());
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(_Preview),
      matchesGoldenFile('goldens/karty_boost_activation.png'),
    );
  });
}

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF041227),
        body: Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              _Frame(
                title: '1  KAYNAK',
                note: 'İki köşe şimşeği tek noktada toplanır.',
                progress: 0.30,
              ),
              SizedBox(width: 18),
              _Frame(
                title: '2  DARBE',
                note: 'Sıkışan enerji kıvrılarak açılır, parçalar savrulur.',
                progress: 0.47,
              ),
              SizedBox(width: 18),
              _Frame(
                title: '3  ÇARPMA',
                note: 'Enerji puana iner; kısa bir halka ile tamamlanır.',
                progress: 0.89,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Frame extends StatefulWidget {
  const _Frame({
    required this.title,
    required this.note,
    required this.progress,
  });

  final String title;
  final String note;
  final double progress;

  @override
  State<_Frame> createState() => _FrameState();
}

class _FrameState extends State<_Frame> {
  final _boostProgress = ValueNotifier(1.0);

  @override
  void dispose() {
    _boostProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const scale = 0.38;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFF1CB1F5),
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.note,
            style: const TextStyle(
              color: Color(0xFF8FA0B5),
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ColoredBox(
                color: const Color(0xFF071A35),
                child: Stack(
                  children: [
                    const Positioned(
                      left: 72,
                      right: 72,
                      top: 67,
                      child: _TopTarget(),
                    ),
                    Positioned(
                      left: 58,
                      right: 58,
                      top: 170,
                      height: 305,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF68D73D),
                                  Color(0xFF56BEEA),
                                  Color(0xFFA647F0),
                                  Color(0xFFFDC041),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 58,
                      right: 58,
                      top: 170,
                      height: 305,
                      child: KartyBoostEdgeMeter(
                        scale: scale,
                        charge: 5,
                        chargeGoal: 5,
                        isReady: false,
                        isActive: false,
                        boostProgress: _boostProgress,
                        onTap: () {},
                        interactive: false,
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: KartyBoostActivationPainter(
                          progress: widget.progress,
                          scale: scale,
                          topLeftSource: const Offset(88, 204),
                          bottomRightSource: const Offset(252, 438),
                          merge: const Offset(180, 335),
                          target: const Offset(228, 82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTarget extends StatelessWidget {
  const _TopTarget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF93D334),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1CB1F5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Text(
            '×3',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

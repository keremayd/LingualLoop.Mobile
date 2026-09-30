import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/karty_answer_feedback_effect.dart';
import 'package:lingualloop/ui/widgets/karty_boost_edge_meter.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(File('assets/fonts/Inter-SemiBold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  });

  testWidgets('Karty birleşik efekt sistemi', (tester) async {
    const size = Size(1500, 700);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _PreviewPage());
    await tester.runAsync(() => precacheImage(
          const ResizeImage(AssetImage('assets/icons/boost-bolt.png'),
              height: 270),
          tester.element(find.byType(_PreviewPage)),
        ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));
    await tester.pump();

    await expectLater(
      find.byType(_PreviewPage),
      matchesGoldenFile('goldens/karty_effect_v2.png'),
    );
  });
}

class _PreviewPage extends StatefulWidget {
  const _PreviewPage();

  @override
  State<_PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<_PreviewPage> {
  final _normalCorrect = ValueNotifier(false);
  final _correct = ValueNotifier(false);
  final _wrong = ValueNotifier(false);
  final _progress = ValueNotifier(0.58);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _correct.value = true;
    });
  }

  @override
  void dispose() {
    _normalCorrect.dispose();
    _correct.dispose();
    _wrong.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF041227),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: _Column(
                  title: '1  SAKİN ONAY',
                  note: 'Kelime + kalınlık bandı yeşil.\n'
                      'Rozet, glow ve ayrı kutlama yok.',
                  child: _Stage(
                    correct: _correct,
                    wrong: _wrong,
                    progress: _progress,
                    charge: 3,
                    correctBand: true,
                  ),
                ),
              ),
              Expanded(
                child: _Column(
                  title: '2  TEK İLERLEME',
                  note: 'Her doğru kartın kendi kenarında\n'
                      'bir dikey şimşek doldurur.',
                  child: _Stage(
                    correct: _normalCorrect,
                    wrong: _wrong,
                    progress: _progress,
                    charge: 3,
                  ),
                ),
              ),
              Expanded(
                child: _Column(
                  title: '3  BOOST HAZIR',
                  note: 'İki şimşek dolunca sağ alttakine dokun.\n'
                      'Yazı ve sekme yok; şimşek doğrudan basılır.',
                  child: _Stage(
                    correct: _normalCorrect,
                    wrong: _wrong,
                    progress: _progress,
                    charge: 5,
                    ready: true,
                  ),
                ),
              ),
              Expanded(
                child: _Column(
                  title: '4  BOOST AKTİF',
                  note: 'Aynı kenar şimşekleri kalan süreyi anlatır.\n'
                      'İkinci kontur ve hareketli bar ikonu yok.',
                  child: _Stage(
                    correct: _normalCorrect,
                    wrong: _wrong,
                    progress: _progress,
                    charge: 0,
                    active: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.title,
    required this.note,
    required this.child,
  });

  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1CB1F5),
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            note,
            style: const TextStyle(
              color: Color(0xFF8FA0B5),
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.correct,
    required this.wrong,
    required this.progress,
    required this.charge,
    this.correctBand = false,
    this.ready = false,
    this.active = false,
  });

  final ValueNotifier<bool> correct;
  final ValueNotifier<bool> wrong;
  final ValueNotifier<double> progress;
  final int charge;
  final bool correctBand;
  final bool ready;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const scale = 0.55;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 315,
          child: KartyFeedbackWord(
            article: 'die',
            text: 'Zahnbürste',
            scale: scale,
            isCorrectActive: correct,
            isWrongActive: wrong,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: 230,
          height: 345,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      if (correctBand)
                        const BoxShadow(
                          color: Color(0xFF628C22),
                          offset: Offset(0, 10),
                        ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(5, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(13),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
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
              Positioned.fill(
                child: KartyBoostEdgeMeter(
                  scale: scale,
                  charge: charge,
                  chargeGoal: 5,
                  isReady: ready,
                  isActive: active,
                  boostProgress: progress,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/karty_answer_feedback_effect.dart';
import 'package:lingualloop/ui/widgets/mascot_mark.dart';
import 'package:lingualloop/ui/widgets/quest_reward_celebration.dart';

/// Karty efektleri: mevcut hâl ve öneri, film şeridi olarak.
/// **Üretim kodu değil.**
void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(File('assets/fonts/Inter-SemiBold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  });

  testWidgets('karty efektleri', (tester) async {
    const size = Size(1240, 980);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _Page());
    // Mevcut efektler animasyonlu; ortalarında yakalayalım.
    await tester.pump(const Duration(milliseconds: 380));

    await expectLater(
      find.byType(_Page),
      matchesGoldenFile('goldens/karty_effects.png'),
    );
  });
}

const _bg = Color(0xFF041227);
const _muted = Color(0xFF8FA0B5);
const _accent = Color(0xFF1CB1F5);
const _s = 430 / 750;

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: _bg,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Section(
                title: 'DOĞRU CEVAP · ŞU AN',
                note: 'Bulanık altın kontur (FFD52F — palette yok) + blur. '
                    'Uygulamanın hiçbir yerinde bu dil yok.',
                child: _CurrentCorrect(),
              ),
              SizedBox(height: 10),
              _Section(
                title: 'DOĞRU CEVAP · ÖNERİ — uygulamanın kendi ışık reçetesi',
                note: 'Görev ödülü ve seri kilometre taşıyla AYNI painter '
                    '(LightRaysOnly): 10 dilim, krem FFF1DC, keskin kenar.',
                child: _ProposedCorrect(),
              ),
              SizedBox(height: 10),
              _Section(
                title: 'BOOST ŞİMŞEĞİ · ŞU AN ↔ ÖNERİ',
                note: 'Şimşek altın (FFB000). §5: şimşek beyazdır. Öneri: '
                    'beyaz şimşek + accent mavi enerji — boost artık ligi çarpıyor.',
                child: _BoltCompare(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.note, required this.child});
  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: _accent,
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(note,
            style: const TextStyle(
                color: _muted,
                fontFamily: 'Inter',
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AlwaysOn extends ValueNotifier<bool> implements ValueListenable<bool> {
  _AlwaysOn() : super(true);
}

class _CurrentCorrect extends StatelessWidget {
  const _CurrentCorrect();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Center(
        child: KartyFeedbackWord(
          article: 'die',
          text: 'Zahnbürste',
          scale: _s,
          isCorrectActive: _AlwaysOn(),
          isWrongActive: ValueNotifier<bool>(false),
        ),
      ),
    );
  }
}

class _ProposedCorrect extends StatelessWidget {
  const _ProposedCorrect();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final p in const [0.0, 0.25, 0.5, 0.75])
            // Hücreler kırpılıyor: ışınlar kutudan taşıyor ve komşu kareye
            // karışıp yargıyı bozuyor (CLAUDE.md'de kayıtlı tuzak).
            SizedBox(
              width: 230,
              height: 230,
              child: ClipRect(
                child: Stack(
                alignment: Alignment.center,
                children: [
                  LightRaysOnly(box: 230, progress: p),
                  // Kelime ışığın önünde; ışık ortam, kelime özne.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF52A2A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('die',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 16,
                                height: 1,
                                fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Zahnbürste',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 30,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoltCompare extends StatelessWidget {
  const _BoltCompare();

  @override
  Widget build(BuildContext context) {
    Widget bolts(Color face, Color? energy, String label) => Column(
          children: [
            SizedBox(
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (energy != null)
                    Container(
                      width: 240,
                      height: 76,
                      decoration: BoxDecoration(
                        color: energy.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Opacity(
                            opacity: i < 3 ? 1 : 0.25,
                            child: MascotBolt(
                              size: 34,
                              color: face,
                              shadowColor: face,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Text(label,
                style: const TextStyle(
                    color: _muted,
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        bolts(const Color(0xFFFFB000), null, 'ŞU AN · altın şimşek'),
        bolts(const Color(0xFFF6EDE4), _accent,
            'ÖNERİ · beyaz şimşek, accent mavi enerji'),
      ],
    );
  }
}

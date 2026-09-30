import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';

/// Günlük yeni kelime durumunu kullanıcıya nasıl söyleyeceğimizin önizlemesi.
///
/// **Üretim kodu değil.** Onay alınana kadar hiçbir şey ekrana bağlanmadı;
/// buradaki widget'lar yalnız çizim için.
void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(
        File('assets/fonts/Inter-SemiBold.ttf').readAsBytes().then(
              (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
            ));
    await loader.load();
  });

  testWidgets('gunluk durum onerileri', (tester) async {
    tester.view.physicalSize = const Size(1290, 2760);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _PreviewPage());
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(_PreviewPage),
      matchesGoldenFile('goldens/karty_daily_state.png'),
    );
  });
}

const _bg = Color(0xFF041227);
const _panel = Color(0xFF0B2143);
const _muted = Color(0xFF8FA0B5);
const _cream = Color(0xFFE9EEF5);
const _green = Color(0xFF93D334);
const _greenDeep = Color(0xFF628C22);
const _gold = Color(0xFFFFC93A);
const _accent = Color(0xFF1CB1F5);

class _PreviewPage extends StatelessWidget {
  const _PreviewPage();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          child: Column(
            children: const [
              _Section(
                title: '1 · Tanışma kartındaki etiket sayaca dönüşür',
                note: 'Yeni kaplama yok — var olan "Yeni kelime" satırı.',
                child: _LabelVariants(),
              ),
              _Section(
                title: '2 · Kota dolduğu anda tek geçiş kartı',
                note: 'Duvar değil eşik: dokunulur, pratik devam eder.',
                child: _ThresholdCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
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
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _cream,
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            note,
            style: const TextStyle(
              color: _muted,
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Üç etiket varyantı, gerçek cihaz genişliğindeki puntoyla.
class _LabelVariants extends StatelessWidget {
  const _LabelVariants();

  @override
  Widget build(BuildContext context) {
    const scale = 430 / 750;
    return Column(
      children: [
        _variant('A · düz kesir', const _CounterLabel(scale: scale, done: 3)),
        _variant('B · noktalı şerit', const _PipLabel(scale: scale, done: 3)),
        _variant(
          'C · mevcut hâl (sayaçsız)',
          const Text(
            'Yeni kelime',
            style: TextStyle(
              color: _muted,
              fontFamily: 'Inter',
              fontSize: 26 * scale,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2 * scale,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 420 * scale,
          child: DepthPressableButton(
            text: 'ANLADIM',
            width: 420 * scale,
            height: 116 * scale,
            radius: 30 * scale,
            shadowOffset: 10 * scale,
            backgroundColor: _green,
            shadowColor: _greenDeep,
            fontSize: 34 * scale,
            fontWeight: FontWeight.w900,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _variant(String caption, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            caption,
            style: const TextStyle(
              color: _accent,
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// A — "Yeni kelime · 3/8". Kesir, biletin `13/15` kesiriyle aynı dil.
class _CounterLabel extends StatelessWidget {
  const _CounterLabel({required this.scale, required this.done});

  final double scale;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'Yeni kelime',
          style: TextStyle(
            color: _muted,
            fontFamily: 'Inter',
            fontSize: 26 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2 * scale,
          ),
        ),
        SizedBox(width: 12 * scale),
        Text(
          '$done',
          style: TextStyle(
            color: _cream,
            fontFamily: 'Inter',
            fontSize: 26 * scale,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '/8',
          style: TextStyle(
            color: _muted,
            fontFamily: 'Inter',
            fontSize: 26 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// B — sekiz nokta. Sayı okumadan "az kaldı" görülüyor.
class _PipLabel extends StatelessWidget {
  const _PipLabel({required this.scale, required this.done});

  final double scale;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Yeni kelime',
          style: TextStyle(
            color: _muted,
            fontFamily: 'Inter',
            fontSize: 26 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2 * scale,
          ),
        ),
        SizedBox(height: 10 * scale),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(8, (index) {
            final filled = index < done;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4 * scale),
              width: 14 * scale,
              height: 14 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? _gold : _panel,
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Kota dolduğunda deste konumunda bir kez görünen eşik kartı.
class _ThresholdCard extends StatelessWidget {
  const _ThresholdCard();

  @override
  Widget build(BuildContext context) {
    const scale = 430 / 750;
    return Center(
      child: SizedBox(
        width: 535 * scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 535 * scale,
              height: 560 * scale,
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(40 * scale),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sekiz nokta, hepsi dolu — az önceki sayacın bittiği hâl.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(8, (index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 5 * scale),
                        width: 18 * scale,
                        height: 18 * scale,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gold,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 44 * scale),
                  Text(
                    'Bugünün 8 yeni\nkelimesi tamam',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _cream,
                      fontFamily: 'Inter',
                      fontSize: 44 * scale,
                      height: 1.24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 22 * scale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 54 * scale),
                    child: Text(
                      'Yarın yenileri gelecek.\nŞimdi bildiklerini tazeleyelim.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontFamily: 'Inter',
                        fontSize: 26 * scale,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40 * scale),
            DepthPressableButton(
              text: 'PRATİĞE DEVAM',
              width: 460 * scale,
              height: 116 * scale,
              radius: 30 * scale,
              shadowOffset: 10 * scale,
              backgroundColor: _green,
              shadowColor: _greenDeep,
              fontSize: 34 * scale,
              fontWeight: FontWeight.w900,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingualloop/ui/widgets/mascot_mark.dart';
import 'package:lingualloop/ui/widgets/quest_reward_celebration.dart';

/// Karty efekt sistemi: tek malzeme, dört yoğunluk. **Üretim kodu değil.**
void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(File('assets/fonts/Inter-SemiBold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  });

  testWidgets('efekt sistemi', (tester) async {
    const size = Size(1500, 620);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _Page());
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(_Page),
      matchesGoldenFile('goldens/karty_effect_system.png'),
    );
  });
}

const _bg = Color(0xFF041227);
const _muted = Color(0xFF8FA0B5);
const _accent = Color(0xFF1CB1F5);
const _green = Color(0xFF93D334);
const _greenDeep = Color(0xFF628C22);
const _bolt = Color(0xFFF6EDE4);

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: _bg,
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Cell(
                level: '1',
                title: 'DOĞRU CEVAP',
                note: 'Kalınlık bandı yeşile döner, kelime %3 büyür.\n'
                    'Işık YOK. Sessiz onay.',
                child: _Level1(),
              ),
              _Cell(
                level: '2',
                title: '3+ DOĞRU SERİSİ',
                note: 'Şimşekler dolar + kısık ışık (%35 doz).\n'
                    'İlk kez bir şey "oluyor".',
                child: _Level2(),
              ),
              _Cell(
                level: '3',
                title: 'BOOST AKTİF',
                note: 'Kart kenarında şimşek dizisi, accent mavi.\n'
                    'Elektrik değil — uygulamanın kendi şimşeği.',
                child: _Level3(),
              ),
              _Cell(
                level: '4',
                title: 'OTURUM SONU',
                note: 'Tam ışık reçetesi + maskot.\n'
                    'Kutlama buraya saklanıyor.',
                child: _Level4(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(
      {required this.level,
      required this.title,
      required this.note,
      required this.child});
  final String level;
  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF163258),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(level,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 7),
              Text(title,
                  style: const TextStyle(
                      color: _accent,
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 4),
            SizedBox(
              height: 34,
              child: Text(note,
                  style: const TextStyle(
                      color: _muted,
                      fontFamily: 'Inter',
                      fontSize: 10,
                      height: 1.35,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            Expanded(child: ClipRect(child: Center(child: child))),
          ],
        ),
      ),
    );
  }
}

Widget _word({double scale = 1}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 26 * scale,
          padding: EdgeInsets.symmetric(horizontal: 8 * scale),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF52A2A),
            borderRadius: BorderRadius.circular(9 * scale),
          ),
          child: Text('die',
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 13 * scale,
                  height: 1,
                  fontWeight: FontWeight.w900)),
        ),
        SizedBox(width: 7 * scale),
        Text('Zahnbürste',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 26 * scale,
                fontWeight: FontWeight.w900)),
      ],
    );

/// Kart: beyaz çerçeve + gradyan yüz, altında kalınlık bandı.
Widget _card({required Color band}) => SizedBox(
      width: 156,
      height: 216,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 10,
            child: Container(
              height: 206,
              decoration: BoxDecoration(
                color: band,
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          Container(
            width: 156,
            height: 206,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
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
        ],
      ),
    );

class _Level1 extends StatelessWidget {
  const _Level1();
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kelime %3 büyümüş.
          Transform.scale(scale: 1.03, child: _word()),
          const SizedBox(height: 12),
          // Kalınlık bandı yeşil: onay kartın kendi katmanından geliyor.
          _card(band: _greenDeep),
        ],
      );
}

class _Level2 extends StatelessWidget {
  const _Level2();
  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.35,
            child: LightRaysOnly(box: 330, progress: 0.4),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _word(),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  _card(band: const Color(0xFF0B2143)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 5; i++)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: Opacity(
                              opacity: i < 3 ? 1 : 0.22,
                              child: MascotBolt(
                                  size: 20, color: _bolt, shadowColor: _bolt),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
}

class _Level3 extends StatelessWidget {
  const _Level3();
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _word(),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Kenarda dolaşan şimşek dizisi — "elektrik" değil,
                // uygulamanın kendi şimşeği, accent mavi enerjide.
                CustomPaint(
                  size: const Size(200, 240),
                  painter: _BoltRingPainter(),
                ),
                _card(band: const Color(0xFF0B2143)),
              ],
            ),
          ),
        ],
      );
}

class _BoltRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 176,
      height: 226,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(30));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _accent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    // Kenar üzerinde eşit aralıklı şimşekler.
    for (var i = 0; i < 8; i++) {
      final t = i / 8;
      final a = t * 2 * math.pi - math.pi / 2;
      final p = Offset(
        rect.center.dx + math.cos(a) * rect.width / 2,
        rect.center.dy + math.sin(a) * rect.height / 2,
      );
      canvas.drawCircle(p, 7, Paint()..color = _accent);
      canvas.drawCircle(p, 3.4, Paint()..color = _bolt);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Level4 extends StatelessWidget {
  const _Level4();
  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          LightRaysOnly(box: 340, progress: 0.55),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MascotMark(size: 120, pose: MascotPose.cheer),
              const SizedBox(height: 10),
              const Text('Harika!',
                  style: TextStyle(
                      color: Color(0xFFE9EEF5),
                      fontFamily: 'Inter',
                      fontSize: 30,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('+12 ',
                      style: TextStyle(
                          color: _green,
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                  Text('puan',
                      style: TextStyle(
                          color: _muted,
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      );
}

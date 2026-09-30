import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Başlıktaki bilet sayacı — **tek öneri**, seçenek yok.
///
/// Araştırmanın sonucu: Duolingo kapasiteyi aritmetikle değil **kabı
/// çizerek** anlatıyor (dolu/boş kalpler). Bizim tavanımız 15 olduğu için
/// 15 bilet çizilemez; kap bir çubuğa iniyor. `8/15` yazmıyoruz, doluluk
/// görülüyor.
///
/// Tavandayken kırmızı **yok**: dolu olmak iyi bir durum, aciliyet rengi
/// (§2.10 `FF6B3D` = süre bitiyor) onu cezaya çevirir.
///
///   flutter test --update-goldens test/quest_header_final_test.dart
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

    final icons = FontLoader('MaterialIcons');
    final iconBytes = File(
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts'
      '/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    icons.addFont(Future.value(ByteData.view(iconBytes.buffer)));
    await icons.load();
  });

  testWidgets('baslik sayaci - oneri', (tester) async {
    const size = Size(1450, 1000);
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(backgroundColor: _bg, body: _Sheet()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/quest_header_final.png'),
    );
  });
}

const _bg = Color(0xFF041227);
const _cardBorder = Color(0xFF0B2143);
const _track = Color(0xFF0B2143);
const _progress = Color(0xFFFFC93A);
const _muted = Color(0xFF8FA0B5);
const _countdownValue = Color(0xFFE9EEF5);
const _goldDim = Color(0xFFB87E00);

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sol: şimdiki hâl, karşılaştırma için.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Title('ŞİMDİKİ', Color(0xFF5C6C80)),
                SizedBox(height: 14),
                _Caption('8 BİLET'),
                SizedBox(height: 8),
                _HeaderCard(lives: 8, proposal: false),
                SizedBox(height: 18),
                _Caption('TAVANDA'),
                SizedBox(height: 8),
                _HeaderCard(lives: 15, proposal: false),
                SizedBox(height: 22),
                _Caption('GERÇEK BOYUT — 430px'),
                SizedBox(height: 8),
                _RealSize(lives: 8, proposal: false),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // Sağ: öneri.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Title('ÖNERİ', Colors.white),
                SizedBox(height: 6),
                Text(
                  'Kalınlık bandı + tavana göre doluluk çubuğu.\n'
                  'Kesir yok, kırmızı yok.',
                  style: TextStyle(
                    color: _muted,
                    fontFamily: 'Inter',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 14),
                _Caption('8 BİLET'),
                SizedBox(height: 8),
                _HeaderCard(lives: 8, proposal: true),
                SizedBox(height: 18),
                _Caption('TAVANDA — çubuk dolu, uyarı yok'),
                SizedBox(height: 8),
                _HeaderCard(lives: 15, proposal: true),
                SizedBox(height: 22),
                _Caption('GERÇEK BOYUT — 430px'),
                SizedBox(height: 8),
                _RealSize(lives: 8, proposal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF5C6C80),
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _RealSize extends StatelessWidget {
  const _RealSize({required this.lives, required this.proposal});

  final int lives;
  final bool proposal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 430,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 670,
          child: _HeaderCard(lives: lives, proposal: proposal),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.lives, required this.proposal});

  final int lives;
  final bool proposal;

  static const _max = 15;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      radius: 34,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 34, 30, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Günlük Görevler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: const [
                          Icon(Icons.hourglass_bottom_rounded,
                              color: _muted, size: 27),
                          SizedBox(width: 6),
                          Text(
                            '10 sa 56 dk',
                            style: TextStyle(
                              color: _countdownValue,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'sonra yenilenir',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _counter(),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                for (var i = 0; i < 5; i++) ...[
                  if (i > 0) const SizedBox(width: 9),
                  Expanded(
                    child: Container(
                      height: 15,
                      decoration: BoxDecoration(
                        color: _track,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              '0/5 görev · 10 bilet seni bekliyor',
              style: TextStyle(
                color: _muted,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticket(double w, {bool dim = false}) {
    final img =
        Image.asset('assets/icons/ticket.png', width: w, fit: BoxFit.contain);
    if (!dim) return img;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) =>
          const LinearGradient(colors: [_goldDim, _goldDim]).createShader(r),
      child: img,
    );
  }

  Widget _counter() {
    if (!proposal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ticket(118),
          const SizedBox(width: 10),
          Text(
            '$lives',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      );
    }

    const w = 108.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kalınlık bandı: aşağıdaki ödül biletleriyle aynı dil.
            SizedBox(
              width: w,
              height: w * 110 / 172 + 6,
              child: Stack(
                children: [
                  Positioned(left: 0, top: 6, child: _ticket(w, dim: true)),
                  Positioned(left: 0, top: 0, child: _ticket(w)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$lives',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontSize: 42,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        // Kap: tavana göre doluluk. Aritmetik yok, görülüyor.
        SizedBox(
          width: 164,
          height: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: _track)),
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: lives / _max,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: _progress),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBorder,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: const EdgeInsets.only(bottom: 7),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        foregroundDecoration: _NoTopBorderDecoration(
          color: _cardBorder,
          strokeWidth: 2,
          radius: radius,
        ),
        child: child,
      ),
    );
  }
}

class _NoTopBorderDecoration extends Decoration {
  const _NoTopBorderDecoration({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _NoTopBorderBoxPainter(color, strokeWidth, radius);
}

class _NoTopBorderBoxPainter extends BoxPainter {
  _NoTopBorderBoxPainter(this.color, this.strokeWidth, this.radius);

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final inset = strokeWidth / 2;
    final usableRadius = radius.clamp(0, size.shortestSide / 2).toDouble();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(inset, usableRadius)
      ..lineTo(inset, size.height - usableRadius)
      ..quadraticBezierTo(
          inset, size.height - inset, usableRadius, size.height - inset)
      ..lineTo(size.width - usableRadius, size.height - inset)
      ..quadraticBezierTo(size.width - inset, size.height - inset,
          size.width - inset, size.height - usableRadius)
      ..lineTo(size.width - inset, usableRadius);
    canvas.drawPath(path, paint);

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(usableRadius, inset)
        ..quadraticBezierTo(inset, inset, inset, usableRadius),
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(usableRadius, inset),
          Offset(inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - usableRadius, inset)
        ..quadraticBezierTo(
            size.width - inset, inset, size.width - inset, usableRadius),
      cornerPaint
        ..shader = ui.Gradient.linear(
          Offset(size.width - usableRadius, inset),
          Offset(size.width - inset, usableRadius),
          [color.withValues(alpha: 0), color],
        ),
    );

    canvas.restore();
  }
}

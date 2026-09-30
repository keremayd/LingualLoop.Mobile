import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kapasiteyi "kabı çizerek" anlatma denemeleri.
///
/// Duolingo canları **beş kalp** çiziyor: dolu olanlar renkli, boş olanlar
/// sönük. Kapasite aritmetikle değil kabın kendisiyle anlatılıyor ve 5 sayısı
/// keyfi değil — insan 4–5 nesneyi saymadan algılıyor (subitizing).
///
/// Bizim tavanımız 15; 15 bilet çizilemez. Bu sayfa aradaki yolları deniyor.
///
///   flutter test --update-goldens test/quest_capacity_ideas_test.dart
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

  testWidgets('kapasite fikirleri', (tester) async {
    const size = Size(2818, 1000);
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
      matchesGoldenFile('goldens/quest_capacity_ideas.png'),
    );
  });
}

enum _K { plain, fillBar, segments, fiveCap }

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
        children: const [
          _Col(
            k: _K.plain,
            label: 'K0 — SADECE SAYI (H1)',
            note: "Duolingo'nun gem dili. Kapasite yok, sadece bakiye.",
          ),
          SizedBox(width: 26),
          _Col(
            k: _K.fillBar,
            label: 'K1 — DOLUM ÇUBUĞU',
            note: 'Kap çizilir ama sürekli. Doluluk görülür, adet '
                'sayılmaz.',
          ),
          SizedBox(width: 26),
          _Col(
            k: _K.segments,
            label: 'K2 — BÖLMELİ KAP',
            note: 'Her bölme bir bilet. 15 bilet çizilemez ama 15 bölme '
                "sığar — Duolingo'nun mantığı, bizim sayımızla.",
          ),
          SizedBox(width: 26),
          _Col(
            k: _K.fiveCap,
            label: 'K3 — TAVAN 5 OLSAYDI',
            note: "Duolingo'nun birebiri. Ekonomiyi değiştirmek demek; "
                'karşılaştırma için burada.',
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.k, required this.label, required this.note});

  final _K k;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    final full = k == _K.fiveCap ? 5 : 15;
    final mid = k == _K.fiveCap ? 3 : 8;

    return SizedBox(
      width: 670,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 78,
            child: Text(
              note,
              style: const TextStyle(
                color: _muted,
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Caption('YARIDA — $mid/$full'),
          const SizedBox(height: 8),
          _HeaderCard(k: k, lives: mid, max: full),
          const SizedBox(height: 18),
          _Caption('TAVANDA — $full/$full'),
          const SizedBox(height: 8),
          _HeaderCard(k: k, lives: full, max: full),
          const SizedBox(height: 18),
          // Asıl yargı burada: 430px cihazda ölçek 0.642. K2'nin bölmeleri
          // 8 birim — cihazda 5px'e iniyor, okunuyor mu diye bakılmalı.
          const _Caption('GERÇEK BOYUT — 430px cihaz'),
          const SizedBox(height: 8),
          // `Transform.scale` yerleşimi değil yalnız çizimi ölçekler; 670'lik
          // kart 430'luk kutuya sığmayıp taşıyordu. `FittedBox` çocuğu doğal
          // boyutunda ölçer, sonra ölçekler.
          SizedBox(
            width: 430,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 670,
                child: _HeaderCard(k: k, lives: mid, max: full),
              ),
            ),
          ),
        ],
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.k, required this.lives, required this.max});

  final _K k;
  final int lives;
  final int max;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      scale: 1,
      radius: 34,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 34, 30, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
    final img = Image.asset('assets/icons/ticket.png',
        width: w, fit: BoxFit.contain);
    if (!dim) return img;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) =>
          const LinearGradient(colors: [_goldDim, _goldDim]).createShader(r),
      child: img,
    );
  }

  /// Kalınlık bandı: aşağıdaki ödül biletleriyle aynı dil (H1).
  Widget _ticketWithDepth(double w) {
    return SizedBox(
      width: w,
      height: w * 110 / 172 + 6,
      child: Stack(
        children: [
          Positioned(left: 0, top: 6, child: _ticket(w, dim: true)),
          Positioned(left: 0, top: 0, child: _ticket(w)),
        ],
      ),
    );
  }

  Widget _counter() {
    switch (k) {
      case _K.plain:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ticketWithDepth(118),
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

      case _K.fillBar:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ticketWithDepth(100),
                const SizedBox(width: 10),
                Text(
                  '$lives',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: 156,
              height: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Stack(
                  children: [
                    const Positioned.fill(child: ColoredBox(color: _track)),
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: lives / max,
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

      case _K.segments:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ticketWithDepth(100),
                const SizedBox(width: 10),
                Text(
                  '$lives',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            // Her bölme bir bilet: kap çizilir ama 15 tane bilet çizmeden.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < max; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Container(
                    width: 8,
                    height: 14,
                    decoration: BoxDecoration(
                      color: i < lives ? _progress : _track,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

      case _K.fiveCap:
        // Duolingo'nun birebiri: her bilet ayrı çizilir, boş olanlar sönük.
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < max; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _ticket(52, dim: i >= lives),
            ],
          ],
        );
    }
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.scale,
    required this.radius,
    required this.child,
  });

  final double scale;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBorder,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: EdgeInsets.only(bottom: 7 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        foregroundDecoration: _NoTopBorderDecoration(
          color: _cardBorder,
          strokeWidth: 2 * scale,
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

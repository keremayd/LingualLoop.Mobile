import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Görevler başlığındaki bilet sayacı — öneriler.
///
/// İki ayrı sorun:
///  1. **Görsel:** ekrandaki tek "işlenmemiş" bilet burada. Aşağıdaki ödül
///     biletlerinde kalınlık bandı, hâle, köşe rozeti ve hareket var; başlıkta
///     düz PNG + çıplak sayı duruyor.
///  2. **İşlevsel:** ödüller tavanı aşamıyor (§5). Tavandayken "10 bilet seni
///     bekliyor" yazıyor ama o 10 bilet alınırsa çöpe gidecek — ekran bunu
///     söylemiyor.
///
///   flutter test --update-goldens test/quest_header_counter_test.dart
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

  testWidgets('baslik sayaci onerileri', (tester) async {
    const size = Size(2818, 780);
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
      matchesGoldenFile('goldens/quest_header_counter.png'),
    );
  });
}

enum _H { current, depth, capacity, capWarn }

const _bg = Color(0xFF041227);
const _cardBorder = Color(0xFF0B2143);
const _track = Color(0xFF0B2143);
const _progress = Color(0xFFFFC93A);
const _muted = Color(0xFF8FA0B5);
const _countdownValue = Color(0xFFE9EEF5);
const _urgent = Color(0xFFFF6B3D);
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
            h: _H.current,
            label: 'H0 — ŞİMDİKİ',
            note: 'Düz PNG + çıplak sayı. Ekrandaki tek işlenmemiş bilet.',
          ),
          SizedBox(width: 26),
          _Col(
            h: _H.depth,
            label: 'H1 — DERİNLİK',
            note: 'Aşağıdaki ödül biletleriyle aynı kalınlık bandı. Sadece '
                'görsel tutarlılık.',
          ),
          SizedBox(width: 26),
          _Col(
            h: _H.capacity,
            label: 'H2 — KAPASİTE',
            note: 'Tavana göre konum. Yenilenmenin sürüp sürmediği ilk kez '
                'görünüyor.',
          ),
          SizedBox(width: 26),
          _Col(
            h: _H.capWarn,
            label: 'H3 — TAVAN UYARISI',
            note: 'Tavandayken ve ödül beklerken uyarır: alınan bilet '
                'çöpe gidecek.',
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.h, required this.label, required this.note});

  final _H h;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
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
            height: 64,
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
          const SizedBox(height: 12),
          const _Caption('NORMAL — 8 BİLET'),
          const SizedBox(height: 8),
          _HeaderCard(h: h, lives: 8, atCap: false),
          const SizedBox(height: 20),
          const _Caption('TAVANDA — 15/15, ÖDÜL BEKLİYOR'),
          const SizedBox(height: 8),
          _HeaderCard(h: h, lives: 15, atCap: true),
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
  const _HeaderCard({required this.h, required this.lives, required this.atCap});

  final _H h;
  final int lives;
  final bool atCap;

  static const _max = 15;

  @override
  Widget build(BuildContext context) {
    const scale = 1.0;
    final warn = h == _H.capWarn && atCap;

    return _Surface(
      scale: scale,
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
                _counter(warn),
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
            Text(
              warn
                  ? '0/5 görev · biletlerin dolu, ödüller çöpe gider'
                  : '0/5 görev · 10 bilet seni bekliyor',
              style: TextStyle(
                color: warn ? _urgent : _muted,
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

  Widget _counter(bool warn) {
    const w = 118.0;
    final showCap = h == _H.capacity || h == _H.capWarn;
    final withDepth = h != _H.current;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: w,
          height: w * 110 / 172 + (withDepth ? 6 : 0),
          child: Stack(
            children: [
              if (withDepth)
                Positioned(
                  left: 0,
                  top: 6,
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => const LinearGradient(
                      colors: [_goldDim, _goldDim],
                    ).createShader(r),
                    child: Image.asset('assets/icons/ticket.png',
                        width: w, fit: BoxFit.contain),
                  ),
                ),
              Positioned(
                left: 0,
                top: 0,
                child: Image.asset('assets/icons/ticket.png',
                    width: w, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (!showCap)
          Text(
            '$lives',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$lives',
                style: TextStyle(
                  color: warn ? _urgent : Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                '/$_max',
                style: TextStyle(
                  color: warn ? _urgent : _muted,
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
      ],
    );
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Karty oyun ekranının eylem katmanı: mevcut hâl ve öneri.
///
/// **Üretim kodu değil.** Onay alınana kadar ekrana bağlanmadı.
void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    loader.addFont(File('assets/fonts/Inter-SemiBold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer)));
    await loader.load();
  });

  testWidgets('karty eylem katmani', (tester) async {
    tester.view.physicalSize = const Size(1290, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _Page());
    await tester.pump(const Duration(milliseconds: 120));

    await expectLater(
      find.byType(_Page),
      matchesGoldenFile('goldens/karty_actions_redesign.png'),
    );
  });
}

const _bg = Color(0xFF041227);
const _panel = Color(0xFF0B2143);
const _muted = Color(0xFF8FA0B5);
const _cream = Color(0xFFE9EEF5);
const _accent = Color(0xFF1CB1F5);

// Mevcut — ikisi de derinlik tonu / palet dışı
const _oldGreen = Color(0xFF628C22);
const _oldRed = Color(0xFF9B2524);

// Öneri — §2.2 yüz + koyusu
const _green = Color(0xFF93D334);
const _greenDeep = Color(0xFF628C22);
const _red = Color(0xFFF52A2A);
const _redDeep = Color(0xFF9A1414);

const _s = 430 / 750;

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: _bg,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _Block(
                title: 'ŞU AN',
                note: 'Yüzler paletin koyu tonunda — buton sürekli "basılmış" '
                    'renkte duruyor. Tek katman, depth-press yok. Pause ayrı '
                    'bir daire olarak altta yüzüyor.',
                child: _CurrentActions(),
              ),
              _Block(
                title: 'ÖNERİ',
                note: 'Yüz palet tonuna çıktı, altına kendi koyusu geldi. '
                    'Depth-press mekaniği. Pause üst şeride, kapatmanın '
                    'yanına taşındı.',
                child: _ProposedActions(),
              ),
              _Block(
                title: 'ÖNERİ · basılı an',
                note: 'Alt katman söner, yüz onun yerine oturur — uygulamanın '
                    'geri kalanıyla aynı hareket.',
                child: _PressedActions(),
              ),
              _Block(
                title: 'ÖNERİ · üst şerit',
                note: 'Kapat ve duraklat aynı grupta. Alttaki yüzen daire '
                    'kalkıyor, oyun alanı nefes alıyor.',
                child: _ProposedTopBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.note, required this.child});
  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _accent,
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Text(note,
              style: const TextStyle(
                  color: _muted,
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CurrentActions extends StatelessWidget {
  const _CurrentActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FlatIconButton(color: _oldRed, glyph: _Glyph.cross),
            SizedBox(width: 24 * _s),
            _FlatIconButton(color: _oldGreen, glyph: _Glyph.check),
          ],
        ),
        SizedBox(height: 34 * _s),
        Container(
          width: 67 * _s,
          height: 67 * _s,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: _panel),
          child: Center(
            child: CustomPaint(
              size: Size(22 * _s, 26 * _s),
              painter: _PausePainter(color: _muted),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProposedActions extends StatelessWidget {
  const _ProposedActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DepthIconButton(
            face: _red, depth: _redDeep, glyph: _Glyph.cross, pressed: false),
        SizedBox(width: 34 * _s),
        _DepthIconButton(
            face: _green,
            depth: _greenDeep,
            glyph: _Glyph.check,
            pressed: false),
      ],
    );
  }
}

class _PressedActions extends StatelessWidget {
  const _PressedActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DepthIconButton(
            face: _red, depth: _redDeep, glyph: _Glyph.cross, pressed: false),
        SizedBox(width: 34 * _s),
        _DepthIconButton(
            face: _green,
            depth: _greenDeep,
            glyph: _Glyph.check,
            pressed: true),
      ],
    );
  }
}

class _ProposedTopBar extends StatelessWidget {
  const _ProposedTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareChrome(glyph: _Glyph.cross, size: 56 * _s),
        SizedBox(width: 10 * _s),
        _SquareChrome(glyph: _Glyph.pause, size: 56 * _s),
        SizedBox(width: 14 * _s),
        Expanded(
          child: Container(
            height: 26 * _s,
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(13 * _s),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.55,
              child: Container(
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(13 * _s),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16 * _s),
        Text('148',
            style: TextStyle(
                color: _cream,
                fontFamily: 'Inter',
                fontSize: 26 * _s,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _SquareChrome extends StatelessWidget {
  const _SquareChrome({required this.glyph, required this.size});
  final _Glyph glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8 * _s),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.46, size * 0.46),
          painter: glyph == _Glyph.pause
              ? _PausePainter(color: Colors.white)
              : _GlyphPainter(glyph: glyph, color: Colors.white),
        ),
      ),
    );
  }
}

enum _Glyph { cross, check, pause }

class _FlatIconButton extends StatelessWidget {
  const _FlatIconButton({required this.color, required this.glyph});
  final Color color;
  final _Glyph glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130 * _s,
      height: 130 * _s,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28 * _s),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(54 * _s, 54 * _s),
          painter: _GlyphPainter(glyph: glyph, color: Colors.white),
        ),
      ),
    );
  }
}

/// Depth-press: alt katman sabit, yüz onun üstüne çöker (§2.4).
class _DepthIconButton extends StatelessWidget {
  const _DepthIconButton({
    required this.face,
    required this.depth,
    required this.glyph,
    required this.pressed,
  });

  final Color face;
  final Color depth;
  final _Glyph glyph;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final size = 130 * _s;
    final offset = 10 * _s;
    return SizedBox(
      width: size,
      height: size + offset,
      child: Stack(
        children: [
          Positioned(
            top: offset,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: pressed ? 0 : 1,
              child: Container(
                height: size,
                decoration: BoxDecoration(
                  color: depth,
                  borderRadius: BorderRadius.circular(28 * _s),
                ),
              ),
            ),
          ),
          Positioned(
            top: pressed ? offset : 0,
            left: 0,
            right: 0,
            child: Container(
              height: size,
              decoration: BoxDecoration(
                color: face,
                borderRadius: BorderRadius.circular(28 * _s),
              ),
              child: Center(
                child: CustomPaint(
                  size: Size(54 * _s, 54 * _s),
                  painter: _GlyphPainter(glyph: glyph, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.glyph, required this.color});
  final _Glyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.17
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    if (glyph == _Glyph.cross) {
      canvas.drawLine(Offset(w * 0.18, w * 0.18), Offset(w * 0.82, w * 0.82), paint);
      canvas.drawLine(Offset(w * 0.82, w * 0.18), Offset(w * 0.18, w * 0.82), paint);
    } else {
      final path = Path()
        ..moveTo(w * 0.16, w * 0.54)
        ..lineTo(w * 0.40, w * 0.78)
        ..lineTo(w * 0.84, w * 0.24);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PausePainter extends CustomPainter {
  _PausePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final barWidth = size.width * 0.3;
    final radius = Radius.circular(barWidth * 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, barWidth, size.height), radius),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width - barWidth, 0, barWidth, size.height),
          radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

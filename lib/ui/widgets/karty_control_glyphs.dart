import 'package:flutter/material.dart';

/// Karty oyun ekranının kontrol glifleri: onay, ret, duraklat, oynat.
///
/// Bunlar §2.5'teki "chunky sticker" ikonları **değil**. O reçete üç renkli,
/// kalınlık bandı olan **illüstrasyon** simgeleri için (alev, kitap, güneş);
/// bunlar ise renkli bir yüzeyin üstünde duran **kaplama** glifleri. Tek
/// renk, tek kalınlık, yuvarlak uçlar — uygulamanın yumuşak dilini taşıyan
/// ama üstünde durduğu butonla yarışmayan çizgi.
///
/// PNG'den çevrilmelerinin sebebi: 64 birimlik bir ızgara 130 birimlik
/// butonun içinde esnetiliyor ve kenarları yumuşuyordu. Painter cihazın
/// gerçek çözünürlüğünde çizer, ayrıca rengi parametre olduğu için pasif
/// hâller için ikinci bir dosya gerekmez.
///
/// Hepsi 100 birimlik kutuda tanımlıdır (§2.5'in bu kısmı ortak).
enum KartyControlGlyph { check, cross, pause, play }

class KartyControlMark extends StatelessWidget {
  const KartyControlMark({
    super.key,
    required this.glyph,
    required this.size,
    this.color = Colors.white,
  });

  final KartyControlGlyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ControlGlyphPainter(glyph: glyph, color: color),
    );
  }
}

class _ControlGlyphPainter extends CustomPainter {
  _ControlGlyphPainter({required this.glyph, required this.color});

  final KartyControlGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    switch (glyph) {
      case KartyControlGlyph.check:
        _stroke(canvas, u, [
          Offset(14 * u, 54 * u),
          Offset(39 * u, 78 * u),
          Offset(86 * u, 22 * u),
        ]);
      case KartyControlGlyph.cross:
        _stroke(canvas, u, [Offset(18 * u, 18 * u), Offset(82 * u, 82 * u)]);
        _stroke(canvas, u, [Offset(82 * u, 18 * u), Offset(18 * u, 82 * u)]);
      case KartyControlGlyph.pause:
        _bar(canvas, u, 24 * u);
        _bar(canvas, u, 58 * u);
      case KartyControlGlyph.play:
        // Üçgen de yuvarlatılmış: aynı yolu hem doldur hem konturla.
        final path = Path()
          ..moveTo(28 * u, 18 * u)
          ..lineTo(84 * u, 50 * u)
          ..lineTo(28 * u, 82 * u)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14 * u
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  void _stroke(Canvas canvas, double u, List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15 * u
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _bar(Canvas canvas, double u, double left) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 16 * u, 18 * u, 68 * u),
        Radius.circular(8 * u),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ControlGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

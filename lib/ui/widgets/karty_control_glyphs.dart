import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Uygulamanın kontrol glifleri: onay, ret, duraklat, oynat, geri ve yavaş
/// çalma (salyangoz).
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
enum KartyControlGlyph { check, cross, pause, play, back, slow }

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
      case KartyControlGlyph.back:
        _stroke(canvas, u, [
          Offset(48 * u, 18 * u),
          Offset(16 * u, 50 * u),
          Offset(48 * u, 82 * u),
        ]);
        _stroke(canvas, u, [Offset(18 * u, 50 * u), Offset(84 * u, 50 * u)]);
      case KartyControlGlyph.slow:
        _snail(canvas, size, u);
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

  /// Yavaş çalma: salyangoz. Düğmenin üstüne "YAVAŞ" yazmak kaba bulundu
  /// (kullanıcı, 11 Kas 2026); kaplumbağa da çizildi ama gerçek boyda sarmal
  /// kabuk daha net okunuyor. Ayrıntılar boşlukla çizilir, ikinci renk yok.
  void _snail(Canvas canvas, Size size, double u) {
    canvas.saveLayer(Offset.zero & size, Paint());
    final fill = Paint()..color = color;
    Paint stroke(double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final clear = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ayak, baş ve göz sapları.
    final foot = Path()
      ..addRRect(RRect.fromLTRBR(
          8 * u, 72 * u, 90 * u, 84 * u, Radius.circular(6 * u)));
    canvas.drawPath(foot, fill);
    canvas.drawPath(foot, stroke(6 * u));
    canvas.drawLine(
        Offset(74 * u, 78 * u), Offset(84 * u, 60 * u), stroke(16 * u));
    canvas.drawLine(
        Offset(82 * u, 56 * u), Offset(77 * u, 38 * u), stroke(6 * u));
    canvas.drawLine(
        Offset(88 * u, 56 * u), Offset(94 * u, 39 * u), stroke(6 * u));
    canvas.drawCircle(Offset(77 * u, 36 * u), 5 * u, fill);
    canvas.drawCircle(Offset(94 * u, 37 * u), 5 * u, fill);

    // Kabuk; sarmal ve ayakla arası boşluk.
    const center = Offset(42, 50);
    canvas.drawCircle(center * u, 28 * u, fill);
    final spiral = Path();
    const turns = 1.8;
    for (var i = 0; i <= 80; i++) {
      final t = i / 80;
      final angle = -math.pi / 2 + t * turns * 2 * math.pi;
      final radius = (3 + 18 * t) * u;
      final point = center * u +
          Offset(radius * math.cos(angle), radius * math.sin(angle));
      i == 0
          ? spiral.moveTo(point.dx, point.dy)
          : spiral.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(spiral, clear..strokeWidth = 5 * u);
    canvas.drawArc(Rect.fromCircle(center: center * u, radius: 30 * u),
        math.pi * .18, math.pi * .64, false, clear..strokeWidth = 4 * u);
    canvas.restore();
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

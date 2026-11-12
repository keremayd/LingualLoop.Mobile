import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/learning_card_gradient.dart';
import 'package:lingualloop/ui/widgets/quest_icons.dart';

/// Karty Yolu'nun yan duraklarının simgeleri: Artikel Pusulası ve Rövanş.
/// Görev ikonlarının reçetesiyle çizilir (§2.5): tombul gövde, altında koyu
/// kalınlık bandı, net iki tonlu yüzey, sol üstte ince parlama.

/// Köşeleri yuvarlatmak için gövde hem doldurulur hem aynı renkle yuvarlak
/// birleşimli konturlanır (görev ikonlarının `_fillChunky`'si).
void _fillChunky(Canvas canvas, Path path, Color color, double u,
    {double stroke = 7}) {
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * u
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round,
  );
}

void _gloss(Canvas canvas, Path body, double u) {
  canvas.drawPath(
    body.shift(Offset(-1.5 * u, -2 * u)),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * u
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * u),
  );
}

/// Artikel Pusulası: oyunun sürükleme anının küçüğü. Üstteki kart desteden
/// kopup der'e gidiyor; hedefler oyundaki yerlerinde (solda die, tepede das,
/// sağda der) ve üstlerinde oyundaki yön okları. Modun adındaki pusulayı
/// çizmiyor: simge adı değil oyunda yapılan işi anlatır (kullanıcı kararı,
/// 6 Kas 2026).
class ArticleDragMark extends StatelessWidget {
  const ArticleDragMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _ArticleDragPainter(),
    );
  }
}

class _ArticleDragPainter extends CustomPainter {
  const _ArticleDragPainter();

  // Artikel renkleri her yerde aynı (§2.0): der mavi, die kırmızı, das
  // turuncu. Açık ve koyu tonlar belgeli paletlerden.
  static const _der = (Color(0xFF1CB1F5), Color(0xFF0E6A98));
  static const _die = (Color(0xFFF52A2A), Color(0xFF9A1414));
  static const _das = (Color(0xFFFFB000), Color(0xFFC97800));

  /// Artikel kartı: beyaz çerçeve, lacivert yüz, altta kelimenin yeri.
  /// Arkada kalan kartın yüzü sade, çerçevesi arka kart tonunda.
  static void _card(
    Canvas canvas,
    double u, {
    required Offset center,
    required double width,
    required double height,
    required double angle,
    bool back = false,
  }) {
    final rim = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: width * u,
        height: height * u,
      ),
      Radius.circular(9 * u),
    );
    // Kalınlık bandı dönmez: hep aşağı iner.
    for (final (dy, color) in [
      (4.5, back ? const Color(0xFF9DA5AF) : const Color(0xFFBCAB9E)),
      (0.0, back ? const Color(0xFFD8DCE4) : const Color(0xFFF6EDE4)),
    ]) {
      canvas.save();
      canvas.translate(center.dx * u, (center.dy + dy) * u);
      canvas.rotate(angle);
      canvas.drawRRect(rim, Paint()..color = color);
      canvas.restore();
    }
    canvas.save();
    canvas.translate(center.dx * u, center.dy * u);
    canvas.rotate(angle);
    if (!back) {
      canvas.save();
      canvas.clipRRect(rim);
      canvas.drawRect(
        Rect.fromLTWH(-width * u, -height * u / 2, width * u * 2, 5 * u),
        Paint()..color = Colors.white,
      );
      canvas.restore();
    }
    canvas.drawRRect(
      rim.deflate(4.5 * u),
      Paint()..color = back ? const Color(0xFF0B2143) : const Color(0xFF17345E),
    );
    if (!back) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, height * u * 0.2),
            width: width * u * 0.58,
            height: 6.5 * u,
          ),
          Radius.circular(3.25 * u),
        ),
        Paint()..color = const Color(0xFFF6EDE4),
      );
    }
    canvas.restore();
  }

  /// Oyundaki hedef: düz yüz, altında kalınlık, içinde beyaz yön oku.
  static void _target(
    Canvas canvas,
    double u, {
    required Offset center,
    required double width,
    required double height,
    required (Color, Color) palette,
    required double arrow,
  }) {
    final rect = Rect.fromCenter(
      center: center * u,
      width: width * u,
      height: height * u,
    );
    final radius = Radius.circular(8 * u);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(Offset(0, 4.5 * u)), radius),
      Paint()..color = palette.$2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = palette.$1,
    );
    final size = height * 0.62 * u;
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(arrow);
    canvas.drawPath(
      Path()
        ..moveTo(-size / 2, 0)
        ..lineTo(size / 2, 0)
        ..moveTo(size * 0.08, -size * 0.42)
        ..lineTo(size / 2, 0)
        ..lineTo(size * 0.08, size * 0.42),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * u
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    _card(
      canvas,
      u,
      center: const Offset(39, 60),
      width: 42,
      height: 54,
      angle: -0.04,
      back: true,
    );
    _card(
      canvas,
      u,
      center: const Offset(55, 58),
      width: 44,
      height: 56,
      angle: 0.17,
    );
    _target(
      canvas,
      u,
      center: const Offset(44, 12),
      width: 34,
      height: 20,
      palette: _das,
      arrow: -math.pi / 2,
    );
    _target(
      canvas,
      u,
      center: const Offset(15, 56),
      width: 30,
      height: 20,
      palette: _die,
      arrow: math.pi,
    );
    _target(
      canvas,
      u,
      center: const Offset(83, 54),
      width: 34,
      height: 23,
      palette: _der,
      arrow: 0,
    );
  }

  @override
  bool shouldRepaint(covariant _ArticleDragPainter oldDelegate) => false;
}

/// Rövanş: yanlış bilinen Karty kartı (gökkuşağı yüz, ortada kırmızı çarpı)
/// ve onu geri getiren yeşil dönüş oku — ana ekrandaki Rövanş görselinin
/// sticker hâli. Ok, görev ikonu ve Pekiştirme kapısıyla aynı yoldan
/// ([revengeArrowBody]).
class RevengeCardMark extends StatelessWidget {
  const RevengeCardMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _RevengeCardPainter(),
    );
  }
}

class _RevengeCardPainter extends CustomPainter {
  const _RevengeCardPainter();

  static const _rimLight = Color(0xFFFFFFFF);
  static const _rim = Color(0xFFF6EDE4);
  static const _rimDepth = Color(0xFFBCAB9E);
  static const _red = (Color(0xFFFF7A5C), Color(0xFFF52A2A), Color(0xFF9A1414));
  static const _green = (Color(0xFF93D334), Color(0xFF93D334), Color(0xFF628C22));

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    // Kart: hafif sola yatık.
    canvas.save();
    canvas.translate(42 * u, 45 * u);
    canvas.rotate(-0.16);
    final card = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 52 * u, height: 68 * u),
        Radius.circular(10 * u),
      ));
    _fillChunky(canvas, card.shift(Offset(0, 6 * u)), _rimDepth, u, stroke: 4);
    _fillChunky(canvas, card, _rim, u, stroke: 4);
    canvas.save();
    canvas.clipPath(card);
    canvas.drawRect(
      Rect.fromLTWH(-30 * u, -40 * u, 22 * u, 80 * u),
      Paint()..color = _rimLight,
    );
    canvas.restore();
    final faceRect =
        Rect.fromCenter(center: Offset.zero, width: 40 * u, height: 56 * u);
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, Radius.circular(6 * u)),
      Paint()..shader = learningCardGradient.createShader(faceRect),
    );
    canvas.restore();

    // Kırmızı çarpı: kartın ortasında, dik.
    final disc = Offset(42 * u, 45 * u);
    final discPath =
        Path()..addOval(Rect.fromCircle(center: disc, radius: 15 * u));
    _fillChunky(canvas, discPath.shift(Offset(0, 4 * u)), _red.$3, u,
        stroke: 2);
    _fillChunky(canvas, discPath, _red.$2, u, stroke: 2);
    canvas.save();
    canvas.clipPath(discPath);
    canvas.drawCircle(
      disc.translate(-7 * u, -7 * u),
      13 * u,
      Paint()..color = _red.$1,
    );
    canvas.restore();
    for (final angle in [math.pi / 4, -math.pi / 4]) {
      canvas.save();
      canvas.translate(disc.dx, disc.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 17 * u, height: 5.5 * u),
          Radius.circular(2.75 * u),
        ),
        Paint()..color = Colors.white,
      );
      canvas.restore();
    }

    // Dönüş oku: sağ altta, kartın köşesini sararak.
    canvas.save();
    canvas.translate(46 * u, 40 * u);
    canvas.scale(0.56);
    final arrow = revengeArrowBody(u);
    _fillChunky(canvas, arrow.shift(Offset(0, 9 * u)), _green.$3, u);
    _fillChunky(canvas, arrow, _green.$2, u);
    canvas.save();
    canvas.clipPath(arrow);
    canvas.drawPath(
      Path()
        ..moveTo(-10 * u, -10 * u)
        ..lineTo(56 * u, -10 * u)
        ..lineTo(30 * u, 110 * u)
        ..lineTo(-10 * u, 110 * u)
        ..close(),
      Paint()..color = const Color(0xFFB6E86A),
    );
    _gloss(canvas, arrow, u);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RevengeCardPainter oldDelegate) => false;
}

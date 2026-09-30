import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Görev kartlarının ikonları. Bayrak simgesiyle aynı dilde çizilir:
/// dolu ve tombul gövde, gövdenin altına inen koyu kalınlık bandı
/// ("vinil sticker" derinliği), bulanık gradyan yerine net iki tonlu yüzey
/// ve sol üstte ince parlama. Her ikonun ışık/gölge ayrımı kendi anlamından
/// gelir: kitabın sol sayfası ışıkta, alevin içi daha parlak, güneşin sol
/// üst yanağı aydınlık.
class QuestIcon extends StatelessWidget {
  const QuestIcon({
    super.key,
    required this.questKey,
    required this.size,
  });

  final String questKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _QuestIconPainter(questKey),
    );
  }
}

class _IconPalette {
  const _IconPalette(this.light, this.face, this.depth);

  final Color light;
  final Color face;
  final Color depth;
}

class _QuestIconPainter extends CustomPainter {
  const _QuestIconPainter(this.questKey);

  final String questKey;

  static const _palettes = <String, _IconPalette>{
    'checkin': _IconPalette(
      Color(0xFFFFE071),
      Color(0xFFFFC932),
      Color(0xFFCE8409),
    ),
    'correct_five': _IconPalette(
      Color(0xFFFFFFFF),
      Color(0xFFF6EDE4),
      Color(0xFFBCAB9E),
    ),
    'learn_three': _IconPalette(
      Color(0xFF6BD1FF),
      Color(0xFF1CB1F5),
      Color(0xFF0E6A98),
    ),
    // Yeşil, ana menü butonuyla aynı iki ton: yüzey 93D334, derinlik 628C22.
    'review_two': _IconPalette(
      Color(0xFF93D334),
      Color(0xFF93D334),
      Color(0xFF628C22),
    ),
    'streak_three': _IconPalette(
      Color(0xFFFF7A5C),
      Color(0xFFF52A2A),
      Color(0xFF9A1414),
    ),
  };

  _IconPalette get _palette => _palettes[questKey] ?? _palettes['checkin']!;

  /// Köşeleri yuvarlatmak için gövde hem doldurulur hem aynı renkle
  /// yuvarlak birleşimli konturlanır.
  void _fillChunky(Canvas canvas, Path path, Color color, double u) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * u
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  // ---- gövdeler -------------------------------------------------------

  Path _sunBody(double u) {
    var path = Path()
      ..addOval(
          Rect.fromCircle(center: Offset(50 * u, 50 * u), radius: 23 * u));
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final ray = Path()
        ..addRRect(
          RRect.fromLTRBR(
            -3.5 * u,
            -52 * u,
            3.5 * u,
            -34 * u,
            Radius.circular(3.5 * u),
          ),
        );
      final t = Matrix4.identity()
        ..translateByDouble(50 * u, 50 * u, 0, 1)
        ..rotateZ(angle);
      path = Path.combine(
        PathOperation.union,
        path,
        ray.transform(t.storage),
      );
    }
    return path;
  }

  Path _boltBody(double u) {
    return Path()
      ..moveTo(59 * u, 9 * u)
      ..lineTo(23 * u, 53 * u)
      ..lineTo(47 * u, 53 * u)
      ..lineTo(40 * u, 89 * u)
      ..lineTo(77 * u, 45 * u)
      ..lineTo(53 * u, 45 * u)
      ..close();
  }

  Path _bookPage(double u, {required bool left}) {
    if (left) {
      return Path()
        ..moveTo(50 * u, 30 * u)
        ..cubicTo(41 * u, 21 * u, 26 * u, 17 * u, 13 * u, 21 * u)
        ..lineTo(13 * u, 71 * u)
        ..cubicTo(26 * u, 67 * u, 41 * u, 71 * u, 50 * u, 80 * u)
        ..close();
    }
    return Path()
      ..moveTo(50 * u, 30 * u)
      ..cubicTo(59 * u, 21 * u, 74 * u, 17 * u, 87 * u, 21 * u)
      ..lineTo(87 * u, 71 * u)
      ..cubicTo(74 * u, 67 * u, 59 * u, 71 * u, 50 * u, 80 * u)
      ..close();
  }

  Path _revengeBody(double u) {
    final ring = Path.combine(
      PathOperation.difference,
      Path()
        ..addOval(
            Rect.fromCircle(center: Offset(50 * u, 54 * u), radius: 34 * u)),
      Path()
        ..addOval(
            Rect.fromCircle(center: Offset(50 * u, 54 * u), radius: 17 * u)),
    );
    // Sağ üstte ok başına yer açan kesik.
    final gap = Path()
      ..moveTo(50 * u, 54 * u)
      ..lineTo(50 * u, -10 * u)
      ..lineTo(110 * u, -10 * u)
      ..lineTo(110 * u, 54 * u)
      ..close();
    final open = Path.combine(PathOperation.difference, ring, gap);

    final arrow = Path()
      ..moveTo(50 * u, 4 * u)
      ..lineTo(84 * u, 22 * u)
      ..lineTo(50 * u, 40 * u)
      ..close();

    return Path.combine(PathOperation.union, open, arrow);
  }

  Path _flameBody(double u) => streakFlameBody(u);

  Path _flameInner(double u) => streakFlameInner(u);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final p = _palette;

    final Path body;
    switch (questKey) {
      case 'checkin':
        body = _sunBody(u);
      case 'correct_five':
        body = _boltBody(u);
      case 'learn_three':
        body = Path.combine(
          PathOperation.union,
          _bookPage(u, left: true),
          _bookPage(u, left: false),
        );
      case 'review_two':
        body = _revengeBody(u);
      case 'streak_three':
        body = _flameBody(u);
      default:
        body = _boltBody(u);
    }

    // Kalınlık bandı: gövdenin altına inen koyu katman.
    _fillChunky(canvas, body.shift(Offset(0, 6 * u)), p.depth, u);
    // Ana yüzey.
    _fillChunky(canvas, body, p.face, u);

    canvas.save();
    canvas.clipPath(body);

    // İkincil yüzey: her ikonda anlamdan gelen açık bölge.
    switch (questKey) {
      case 'checkin':
        // Güneşin sol üst yanağı.
        canvas.drawPath(
          Path()
            ..addOval(Rect.fromCircle(
                center: Offset(38 * u, 38 * u), radius: 30 * u)),
          Paint()..color = p.light,
        );
      case 'correct_five':
        // Şimşeğin üst kolu.
        canvas.drawPath(
          Path()
            ..moveTo(-10 * u, -10 * u)
            ..lineTo(110 * u, -10 * u)
            ..lineTo(110 * u, 30 * u)
            ..lineTo(-10 * u, 62 * u)
            ..close(),
          Paint()..color = p.light,
        );
      case 'learn_three':
        // Kitabın sol sayfası ışıkta.
        _fillChunky(canvas, _bookPage(u, left: true), p.light, u);
      case 'review_two':
        // Halkanın sol üst yayı.
        canvas.drawPath(
          Path()
            ..moveTo(-10 * u, -10 * u)
            ..lineTo(56 * u, -10 * u)
            ..lineTo(30 * u, 110 * u)
            ..lineTo(-10 * u, 110 * u)
            ..close(),
          Paint()..color = p.light,
        );
      case 'streak_three':
        // Alevin iç dili.
        _fillChunky(canvas, _flameInner(u), p.light, u);
    }

    // Sol üst kenarda ince parlama.
    canvas.drawPath(
      body.shift(Offset(-1.5 * u, -2 * u)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * u
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * u),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _QuestIconPainter oldDelegate) =>
      oldDelegate.questKey != questKey;
}

/// Tamamlanan görev rozeti: görev ikonlarıyla aynı dilde çizilir —
/// tombul yeşil disk, altında kalınlık bandı, sol üstte açık yüzey ve
/// içinde krem onay işareti.
class QuestCheckMark extends StatelessWidget {
  const QuestCheckMark({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _QuestCheckPainter(),
    );
  }
}

class _QuestCheckPainter extends CustomPainter {
  // Ana menü butonuyla birebir aynı iki yeşil kullanılır.
  static const _face = Color(0xFF93D334);
  static const _depth = Color(0xFF628C22);
  static const _mark = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final disc = Path()
      ..addOval(
          Rect.fromCircle(center: Offset(50 * u, 48 * u), radius: 44 * u));

    // Kalınlık bandı.
    canvas.drawPath(disc.shift(Offset(0, 7 * u)), Paint()..color = _depth);
    // Ana yüzey.
    canvas.drawPath(disc, Paint()..color = _face);

    // Onay işareti: küçük boyutta bulanmaması için gölgesiz ve kalın.
    final check = Path()
      ..moveTo(27 * u, 49 * u)
      ..lineTo(43 * u, 65 * u)
      ..lineTo(74 * u, 31 * u);
    canvas.drawPath(
      check,
      Paint()
        ..color = _mark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16 * u
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _QuestCheckPainter oldDelegate) => false;
}

/// Liderlik/sıralama rozeti: görev ikonlarıyla aynı reçetede tombul kupa.
/// Krem gövde, altında kalınlık bandı, sol üst yüzeyi ışıkta.
class TrophyIcon extends StatelessWidget {
  const TrophyIcon({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _TrophyPainter(),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  // Altın kupa: görev ikonlarıyla aynı üç katmanlı palet.
  static const _light = Color(0xFFFFE071);
  static const _face = Color(0xFFFFC22E);
  static const _depth = Color(0xFFC97A06);

  /// Navbar'daki kupa silueti: dolu kulaklar, geniş çanak, kalın kaide.
  Path _body(double u) {
    final bowl = Path()
      ..moveTo(15 * u, 13 * u)
      ..quadraticBezierTo(15 * u, 6 * u, 22 * u, 6 * u)
      ..lineTo(78 * u, 6 * u)
      ..quadraticBezierTo(85 * u, 6 * u, 85 * u, 13 * u)
      ..cubicTo(85 * u, 36 * u, 75 * u, 54 * u, 50 * u, 58 * u)
      ..cubicTo(25 * u, 54 * u, 15 * u, 35 * u, 15 * u, 6 * u)
      ..close();
    final earLeft = Path()..addOval(Rect.fromLTRB(0, 16 * u, 23 * u, 41 * u));
    final earRight = Path()
      ..addOval(Rect.fromLTRB(77 * u, 16 * u, 100 * u, 41 * u));
    final stem = Path()
      ..addRRect(
        RRect.fromLTRBR(40 * u, 56 * u, 60 * u, 71 * u, Radius.circular(4 * u)),
      );
    final flare = Path()
      ..moveTo(35 * u, 68 * u)
      ..lineTo(65 * u, 68 * u)
      ..lineTo(70 * u, 80 * u)
      ..lineTo(30 * u, 80 * u)
      ..close();
    final base = Path()
      ..addRRect(
        RRect.fromLTRBR(19 * u, 78 * u, 81 * u, 95 * u, Radius.circular(8 * u)),
      );

    var body = Path.combine(PathOperation.union, bowl, earLeft);
    body = Path.combine(PathOperation.union, body, earRight);
    body = Path.combine(PathOperation.union, body, stem);
    body = Path.combine(PathOperation.union, body, flare);
    return Path.combine(PathOperation.union, body, base);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final body = _body(u);

    // Kalınlık bandı.
    canvas.drawPath(body.shift(Offset(0, 5 * u)), Paint()..color = _depth);
    // Ana yüzey.
    canvas.drawPath(body, Paint()..color = _face);

    canvas.save();
    canvas.clipPath(body);
    // Sol üst yüzey ışıkta.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(78 * u, 0)
        ..lineTo(0, 78 * u)
        ..close(),
      Paint()..color = _light,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrophyPainter oldDelegate) => false;
}

/// Seri alevinin gövdesi — **uygulamadaki tek alev şekli.**
///
/// Profil ("Günlük alev"), görevler (`streak_three`) ve seri koruma
/// (`StreakFreezeMark` / `StreakFlameMark`) bu yolu paylaşır. Ayrı ayrı
/// çizilselerdi zamanla birbirinden ayrılır ve buzun içinden çıkan alevin
/// kullanıcının bildiği alev olduğu anlaşılmazdı.
///
/// [tipSway] ve [sway] yalnızca hareketli kullanımlar için; sıfır verildiğinde
/// özgün durağan biçim çıkar. Tabana dokunulmaz — alev kökünden oynamaz.
Path streakFlameBody(double u, {double tipSway = 0, double sway = 0}) {
  return Path()
    ..moveTo((53 + tipSway) * u, 6 * u)
    ..cubicTo((74 + sway) * u, 29 * u, (84 + sway) * u, 46 * u, 84 * u, 62 * u)
    ..cubicTo(84 * u, 81 * u, 69 * u, 94 * u, 50 * u, 94 * u)
    ..cubicTo(31 * u, 94 * u, 16 * u, 81 * u, 16 * u, 62 * u)
    ..cubicTo(16 * u, 47 * u, (26 + sway) * u, 33 * u, (39 + sway) * u, 21 * u)
    ..cubicTo((41 + sway) * u, 35 * u, 45 * u, 43 * u, 51 * u, 49 * u)
    ..cubicTo((57 + tipSway) * u, 38 * u, (57 + tipSway) * u, 22 * u,
        (53 + tipSway) * u, 6 * u)
    ..close();
}

/// Alevin iç dili. Dıştan daha parlak ve daha çok oynar — §2.5/4: ışık ayrımı
/// anlamdan gelir, alevin içi dışından sıcaktır.
Path streakFlameInner(double u, {double innerSway = 0}) {
  return Path()
    ..moveTo((52 + innerSway) * u, 47 * u)
    ..cubicTo(64 * u, 58 * u, 69 * u, 67 * u, 69 * u, 74 * u)
    ..cubicTo(69 * u, 84 * u, 61 * u, 91 * u, 50 * u, 91 * u)
    ..cubicTo(39 * u, 91 * u, 31 * u, 84 * u, 31 * u, 74 * u)
    ..cubicTo(31 * u, 66 * u, 37 * u, 57 * u, (46 + innerSway) * u, 50 * u)
    ..cubicTo(47 * u, 57 * u, 49 * u, 61 * u, 52 * u, 64 * u)
    ..cubicTo(55 * u, 58 * u, 55 * u, 52 * u, (52 + innerSway) * u, 47 * u)
    ..close();
}

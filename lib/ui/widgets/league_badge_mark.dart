import 'package:flutter/material.dart';

class LeagueBadgeMark extends StatelessWidget {
  const LeagueBadgeMark({
    super.key,
    required this.leagueKey,
    required this.size,
    this.locked = false,
  });

  final String leagueKey;
  final double size;

  /// Ulaşılmamış ligler için gri taş gövde + anahtar deliği çizer.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LeagueBadgePainter(
        locked ? LeagueVisuals.lockedPalette : LeagueVisuals.paletteFor(leagueKey),
        locked: locked,
      ),
    );
  }
}

enum LeagueBadgeFinish { matte, gloss, radiant }

class LeagueBadgePalette {
  const LeagueBadgePalette({
    required this.light,
    required this.base,
    required this.dark,
    this.finish = LeagueBadgeFinish.gloss,
    this.starfield = false,
    this.boltColor = Colors.white,
    this.rimColor,
  });

  final Color light;
  final Color base;
  final Color dark;
  final LeagueBadgeFinish finish;
  final bool starfield;
  final Color boltColor;

  /// Prestij rozetlerinde iç jant gövde ailesinden ayrı, parlak bir
  /// renkle çizilir (Pulsar'ın enerji halkası). Null ise beyaz jant kullanılır.
  final Color? rimColor;
}

class LeagueVisuals {
  static const _palettes = <String, LeagueBadgePalette>{
    'merkur': LeagueBadgePalette(
      light: Color(0xFFE7BD84),
      base: Color(0xFFC08A52),
      dark: Color(0xFF7E4E2A),
      finish: LeagueBadgeFinish.matte,
    ),
    'aytasi': LeagueBadgePalette(
      light: Color(0xFFFFFFFF),
      base: Color(0xFFE3EAF1),
      dark: Color(0xFF9AA9B7),
      finish: LeagueBadgeFinish.matte,
    ),
    'yildiz': LeagueBadgePalette(
      light: Color(0xFFFFF0A3),
      base: Color(0xFFFFC93A),
      dark: Color(0xFFB87E00),
    ),
    'kuyruklu': LeagueBadgePalette(
      light: Color(0xFFE4F8FF),
      base: Color(0xFF9BDCF4),
      dark: Color(0xFF3D89AE),
    ),
    'mars': LeagueBadgePalette(
      light: Color(0xFFFFC9A0),
      base: Color(0xFFE0663A),
      dark: Color(0xFF9C3520),
    ),
    'uranus': LeagueBadgePalette(
      light: Color(0xFFD8FFE8),
      base: Color(0xFF6FD3B8),
      dark: Color(0xFF2B8F7B),
    ),
    'saturn': LeagueBadgePalette(
      light: Color(0xFFBFB3FF),
      base: Color(0xFF8C7BF0),
      dark: Color(0xFF4536A4),
    ),
    'nebula': LeagueBadgePalette(
      light: Color(0xFFFFC4F1),
      base: Color(0xFFDF6EE4),
      dark: Color(0xFF9232CC),
      finish: LeagueBadgeFinish.radiant,
    ),
    'kosmoz': LeagueBadgePalette(
      light: Color(0xFF8FB6FF),
      base: Color(0xFF25488A),
      dark: Color(0xFF0A1B3C),
      finish: LeagueBadgeFinish.radiant,
      starfield: true,
      boltColor: Color(0xFFE4F4FF),
    ),
    'supernova': LeagueBadgePalette(
      light: Color(0xFFFFF1A6),
      base: Color(0xFFFFAF1F),
      dark: Color(0xFFD97800),
      finish: LeagueBadgeFinish.radiant,
    ),
    'pulsar': LeagueBadgePalette(
      light: Color(0xFF1E3A66),
      base: Color(0xFF0B1B38),
      dark: Color(0xFF020812),
      finish: LeagueBadgeFinish.radiant,
      starfield: true,
      boltColor: Color(0xFFFFB020),
      rimColor: Color(0xFFFF9300),
    ),
  };

  static LeagueBadgePalette paletteFor(String leagueKey) {
    return _palettes[leagueKey] ?? _palettes['kuyruklu']!;
  }

  /// Kilitli (henüz ulaşılmamış) ligler için nötr gri taş paleti.
  static const lockedPalette = LeagueBadgePalette(
    light: Color(0xFFA6B0BC),
    base: Color(0xFF8792A0),
    dark: Color(0xFF57606C),
    finish: LeagueBadgeFinish.matte,
  );
}

class _LeagueBadgePainter extends CustomPainter {
  const _LeagueBadgePainter(this.palette, {this.locked = false});

  final LeagueBadgePalette palette;
  final bool locked;

  Path _gemPath(Rect r) {
    final w = r.width;
    final h = r.height;
    final l = r.left;
    final t = r.top;

    return Path()
      ..moveTo(l + w * 0.50, t)
      ..cubicTo(l + w * 0.80, t, l + w * 0.94, t + h * 0.09, l + w * 0.965,
          t + h * 0.28)
      ..cubicTo(l + w * 0.99, t + h * 0.44, l + w * 0.99, t + h * 0.60,
          l + w * 0.96, t + h * 0.75)
      ..cubicTo(l + w * 0.925, t + h * 0.92, l + w * 0.77, t + h, l + w * 0.50,
          t + h)
      ..cubicTo(l + w * 0.23, t + h, l + w * 0.075, t + h * 0.92, l + w * 0.04,
          t + h * 0.75)
      ..cubicTo(l + w * 0.01, t + h * 0.60, l + w * 0.01, t + h * 0.44,
          l + w * 0.035, t + h * 0.28)
      ..cubicTo(l + w * 0.06, t + h * 0.09, l + w * 0.20, t, l + w * 0.50, t)
      ..close();
  }

  Path _boltPath(Rect r) {
    final w = r.width;
    final h = r.height;
    final l = r.left;
    final t = r.top;

    return Path()
      ..moveTo(l + w * 0.64, t)
      ..lineTo(l + w * 0.14, t + h * 0.56)
      ..lineTo(l + w * 0.46, t + h * 0.56)
      ..lineTo(l + w * 0.36, t + h)
      ..lineTo(l + w * 0.86, t + h * 0.44)
      ..lineTo(l + w * 0.54, t + h * 0.44)
      ..close();
  }

  Path _sparklePath(Offset c, double r) {
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy - r * 0.18, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + r * 0.18, c.dy + r * 0.18, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy + r * 0.18, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - r * 0.18, c.dy - r * 0.18, c.dx, c.dy - r)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gemRect = Rect.fromLTWH(w * 0.085, 0, w * 0.83, h);
    final depth = _gemPath(gemRect);
    final faceRect = Rect.fromLTWH(
      gemRect.left + gemRect.width * 0.035,
      h * 0.025,
      gemRect.width * 0.93,
      h * 0.90,
    );
    final face = _gemPath(faceRect);

    canvas.drawShadow(depth, Colors.black.withValues(alpha: 0.34), w * 0.05,
        true);
    canvas.drawPath(depth, Paint()..color = palette.dark);

    canvas.save();
    canvas.clipPath(face);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.base);

    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h * 0.24)
        ..lineTo(0, h * 0.40)
        ..close(),
      Paint()..color = palette.light,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w, h * 0.58)
        ..lineTo(w, h)
        ..lineTo(w * 0.28, h)
        ..close(),
      Paint()..color = palette.dark.withValues(alpha: 0.22),
    );

    if (palette.starfield) {
      final gl = gemRect.left;
      final gw = gemRect.width;
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.75);
      canvas.drawCircle(Offset(gl + gw * 0.22, h * 0.30), w * 0.014, starPaint);
      canvas.drawCircle(Offset(gl + gw * 0.76, h * 0.24), w * 0.011, starPaint);
      canvas.drawCircle(Offset(gl + gw * 0.82, h * 0.62), w * 0.013, starPaint);
      canvas.drawCircle(Offset(gl + gw * 0.18, h * 0.70), w * 0.010, starPaint);
      canvas.drawCircle(Offset(gl + gw * 0.60, h * 0.80), w * 0.012, starPaint);
    }

    if (palette.finish != LeagueBadgeFinish.matte) {
      canvas.drawLine(
        Offset(w * 0.02, h * 0.34),
        Offset(w * 0.62, h * 0.06),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.14)
          ..strokeWidth = w * 0.13
          ..strokeCap = StrokeCap.round,
      );
    }

    final rimColor = palette.rimColor;
    canvas.drawPath(
      face,
      Paint()
        ..color = rimColor ??
            Colors.white.withValues(alpha: palette.starfield ? 0.42 : 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * (rimColor == null ? 0.05 : 0.07),
    );
    canvas.restore();

    if (locked) {
      _paintKeyhole(canvas, size, faceRect, gemRect);
      return;
    }

    final boltRect = Rect.fromCenter(
      center: Offset(w * 0.50, faceRect.top + faceRect.height * 0.52),
      width: gemRect.width * 0.50,
      height: h * 0.56,
    );
    final bolt = _boltPath(boltRect);
    final boltOutline = Paint()
      ..color = palette.dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final boltDrop = bolt.shift(Offset(0, h * 0.028));
    final dropPaint = Paint()
      ..color = Color.alphaBlend(
          Colors.black.withValues(alpha: 0.30), palette.dark)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(boltDrop, dropPaint);
    canvas.drawPath(boltDrop, Paint()..color = dropPaint.color);

    canvas.drawPath(bolt, boltOutline);
    canvas.drawPath(bolt, Paint()..color = palette.dark);
    canvas.drawPath(
      bolt.shift(Offset(0, -h * 0.006)),
      Paint()..color = palette.boltColor,
    );

    if (palette.finish == LeagueBadgeFinish.radiant) {
      final gl = gemRect.left;
      final gw = gemRect.width;
      final sparklePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.92);
      canvas.drawPath(
          _sparklePath(Offset(gl + gw * 0.82, h * 0.20), w * 0.065),
          sparklePaint);
      canvas.drawPath(
          _sparklePath(Offset(gl + gw * 0.15, h * 0.66), w * 0.045),
          sparklePaint);
    }
  }

  void _paintKeyhole(Canvas canvas, Size size, Rect faceRect, Rect gemRect) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;
    final cy = faceRect.top + faceRect.height * 0.40;
    final radius = gemRect.width * 0.155;
    final stemHalfTop = gemRect.width * 0.085;
    final stemHalfBottom = gemRect.width * 0.145;
    final stemBottom = faceRect.top + faceRect.height * 0.74;

    Path keyhole(Offset shift) {
      return Path()
        ..addOval(
          Rect.fromCircle(center: Offset(cx, cy) + shift, radius: radius),
        )
        ..moveTo(cx - stemHalfTop + shift.dx, cy + radius * 0.45 + shift.dy)
        ..lineTo(cx + stemHalfTop + shift.dx, cy + radius * 0.45 + shift.dy)
        ..lineTo(cx + stemHalfBottom + shift.dx, stemBottom + shift.dy)
        ..lineTo(cx - stemHalfBottom + shift.dx, stemBottom + shift.dy)
        ..close();
    }

    canvas.drawPath(
      keyhole(Offset(0, h * 0.02)),
      Paint()
        ..color = Color.alphaBlend(
            Colors.black.withValues(alpha: 0.35), palette.dark),
    );
    canvas.drawPath(keyhole(Offset.zero), Paint()..color = palette.dark);
  }

  @override
  bool shouldRepaint(covariant _LeagueBadgePainter oldDelegate) {
    return oldDelegate.palette != palette || oldDelegate.locked != locked;
  }
}

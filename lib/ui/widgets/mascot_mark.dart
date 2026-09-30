import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Maskotun duruşları. Her biri seri kartında bir duruma karşılık gelir.
enum MascotPose {
  /// Seri hiç başlamamış — yatmış, uykulu, davetkâr.
  idle,

  /// Gün kapandı, seri sürüyor — el sallıyor.
  wave,

  /// Kararlılık — çift pazı.
  flex,

  /// Kilometre taşı — kollar havada, kutlama.
  cheer,

  /// Seri kırıldı — omuzlar düşük, kaşlar içe kırık.
  sad,
}

/// Uygulamanın maskotu, **kodla** çizilir.
///
/// Renkler üretilmiş görselden **örneklendi**, göz kararı değil:
/// gövde `4DD2FC → 01BBFE → 0089D8`, şimşek `FEE218`.
///
/// Cilalı 3B hissi üç katmandan geliyor: gövdeye sol üstten inen radyal
/// gradyan, altta koyu hilal, ve sol üstte keskin beyaz parlama. §2.2'nin
/// "gradyan bulanıklığı yasak" kuralı **kaplama** katmanı için; maskot
/// illüstrasyon katmanında ve kendi paletini kullanıyor (§2.2 iki katman).
class MascotMark extends StatelessWidget {
  const MascotMark({
    super.key,
    required this.size,
    this.pose = MascotPose.wave,
  });

  final double size;
  final MascotPose pose;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MascotPainter(pose),
    );
  }
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter(this.pose);

  final MascotPose pose;

  static const _light = Color(0xFF4DD2FC);
  static const _base = Color(0xFF01BBFE);
  static const _dark = Color(0xFF0089D8);
  static const _pupil = Color(0xFF16202E);
  static const _mouth = Color(0xFF7A1024);
  static const _band = Color(0xFF1E2B52);

  bool get _isSad => pose == MascotPose.sad;
  bool get _isIdle => pose == MascotPose.idle;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    // Yatmış duruşta gövde alçalır ve yayılır.
    final cy = _isIdle ? 66.0 : 56.0;
    final rx = _isIdle ? 33.0 : 29.0;
    final ry = _isIdle ? 25.0 : 31.0;

    _legs(canvas, u, cy, ry);
    _arms(canvas, u, cy, rx);
    _antennae(canvas, u, cy, ry);
    _body(canvas, u, cy, rx, ry);
    _face(canvas, u, cy, rx, ry);
  }

  // ------------------------------------------------------------- gövde

  void _body(Canvas canvas, double u, double cy, double rx, double ry) {
    final rect = Rect.fromCenter(
      center: Offset(50 * u, cy * u),
      width: rx * 2 * u,
      height: ry * 2 * u,
    );

    // Ana yüzey: ışık sol üstten geliyor.
    canvas.drawOval(
      rect,
      Paint()
        ..shader = _bodyShader(rect),
    );

    // Alt hilal: gövdenin oturduğu koyu bant. Ayrı bir oval çizilip
    // gövdeyle kesiştiriliyor ki kenarı gövdenin dışına taşmasın.
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(50 * u, (cy + ry * 0.72) * u),
        width: rx * 2.1 * u,
        height: ry * 1.05 * u,
      ),
      Paint()..color = _dark.withValues(alpha: 0.55),
    );
    canvas.restore();

    // Sol üstte keskin parlama — §2.5/5'in maskottaki karşılığı.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset((50 - rx * 0.52) * u, (cy - ry * 0.42) * u),
        width: rx * 0.34 * u,
        height: ry * 0.30 * u,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
  }

  Shader _bodyShader(Rect rect) {
    return RadialGradient(
      center: const Alignment(-0.45, -0.55),
      radius: 1.15,
      colors: const [_light, _base, _dark],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(rect);
  }

  // ------------------------------------------------------------ antenler

  void _antennae(Canvas canvas, double u, double cy, double ry) {
    // Antenler duyguyu taşır: üzgünde sarkar, kutlamada dikleşir.
    final droop = switch (pose) {
      MascotPose.sad => 1.0,
      MascotPose.idle => 0.65,
      MascotPose.cheer => -0.35,
      _ => 0.0,
    };

    for (final side in const [-1.0, 1.0]) {
      final baseX = 50 + side * 11;
      final baseY = cy - ry * 0.92;
      final tipX = baseX + side * (9 + droop * 7);
      final tipY = baseY - (20 - droop * 18);
      final ctrlX = baseX + side * (2 + droop * 9);
      final ctrlY = baseY - (14 - droop * 6);

      canvas.drawPath(
        Path()
          ..moveTo(baseX * u, baseY * u)
          ..quadraticBezierTo(ctrlX * u, ctrlY * u, tipX * u, tipY * u),
        Paint()
          ..color = _base
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.2 * u
          ..strokeCap = StrokeCap.round,
      );

      final ball = Rect.fromCircle(
        center: Offset(tipX * u, tipY * u),
        radius: 6 * u,
      );
      canvas.drawOval(
        ball,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            colors: const [_light, _base],
          ).createShader(ball),
      );

      // Sol antende alın bandı — karakterin kimlik detayı.
      if (side < 0 && !_isSad) {
        canvas.save();
        canvas.translate(baseX * u, (baseY - 7) * u);
        canvas.rotate(-0.18);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: 12 * u,
              height: 6.5 * u,
            ),
            Radius.circular(2 * u),
          ),
          Paint()..color = _band,
        );
        canvas.restore();
      }
    }
  }

  // -------------------------------------------------------------- kollar

  void _arms(Canvas canvas, double u, double cy, double rx) {
    final paint = Paint()
      ..color = _base
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void arm(List<Offset> pts) {
      final p = Path()..moveTo(pts.first.dx * u, pts.first.dy * u);
      for (final o in pts.skip(1)) {
        p.lineTo(o.dx * u, o.dy * u);
      }
      canvas.drawPath(p, paint);
    }

    switch (pose) {
      case MascotPose.cheer:
        arm([Offset(50 - rx * 0.8, cy - 4), const Offset(18, 22), const Offset(14, 10)]);
        arm([Offset(50 + rx * 0.8, cy - 4), const Offset(82, 22), const Offset(86, 10)]);
      case MascotPose.flex:
        arm([Offset(50 - rx * 0.85, cy), Offset(16, cy - 6), Offset(26, cy - 20)]);
        arm([Offset(50 + rx * 0.85, cy), Offset(84, cy - 6), Offset(74, cy - 20)]);
      case MascotPose.wave:
        arm([Offset(50 - rx * 0.85, cy + 4), Offset(18, cy + 16)]);
        arm([Offset(50 + rx * 0.8, cy - 2), Offset(84, cy - 16), Offset(88, cy - 28)]);
      case MascotPose.sad:
        arm([Offset(50 - rx * 0.8, cy + 2), Offset(22, cy + 22)]);
        arm([Offset(50 + rx * 0.8, cy + 2), Offset(78, cy + 22)]);
      case MascotPose.idle:
        arm([Offset(50 - rx * 0.75, cy + 6), Offset(20, cy + 14)]);
        arm([Offset(50 + rx * 0.75, cy + 6), Offset(80, cy + 14)]);
    }
  }

  // ------------------------------------------------------------ bacaklar

  void _legs(Canvas canvas, double u, double cy, double ry) {
    if (_isIdle) return; // yatmış duruşta bacaklar gövdenin altında kalır

    final paint = Paint()..color = _dark;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset((50 + side * 13) * u, (cy + ry + 6) * u),
          width: 20 * u,
          height: 11 * u,
        ),
        paint,
      );
    }
  }

  // ---------------------------------------------------------------- yüz

  void _face(Canvas canvas, double u, double cy, double rx, double ry) {
    final eyeY = cy - ry * 0.12;
    final eyeDx = rx * 0.36;
    final eyeW = rx * 0.52;
    final eyeH = ry * 0.62;

    for (final side in const [-1.0, 1.0]) {
      final ex = 50 + side * eyeDx;
      final rect = Rect.fromCenter(
        center: Offset(ex * u, eyeY * u),
        width: eyeW * u,
        height: eyeH * u,
      );

      canvas.drawOval(rect, Paint()..color = Colors.white);

      // Bebek: üzgünde aşağı kayar, kutlamada yukarı.
      final look = _isSad ? 0.22 : -0.05;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex * u, (eyeY + eyeH * look) * u),
          width: eyeW * 0.62 * u,
          height: eyeH * 0.62 * u,
        ),
        Paint()..color = _pupil,
      );
      canvas.drawCircle(
        Offset((ex - eyeW * 0.16) * u, (eyeY - eyeH * 0.18) * u),
        eyeW * 0.15 * u,
        Paint()..color = Colors.white,
      );

      // Kaş: duygunun asıl taşıyıcısı.
      final browY = eyeY - eyeH * 0.72;
      final inner = Offset((ex + side * -eyeW * 0.45) * u,
          (browY + (_isSad ? -2.0 : 1.0)) * u);
      final outer = Offset((ex + side * eyeW * 0.5) * u,
          (browY + (_isSad ? 3.0 : -1.0)) * u);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = _dark
          ..strokeWidth = 3.4 * u
          ..strokeCap = StrokeCap.round,
      );
    }

    // Yanak parlaması.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset((50 - rx * 0.62) * u, (cy + ry * 0.12) * u),
        width: rx * 0.26 * u,
        height: ry * 0.18 * u,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    _mouthShape(canvas, u, cy, rx, ry, eyeY, eyeH);
  }

  void _mouthShape(Canvas canvas, double u, double cy, double rx, double ry,
      double eyeY, double eyeH) {
    final my = eyeY + eyeH * 0.95;

    if (_isSad) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(50 * u, (my + 4) * u),
          width: 14 * u,
          height: 10 * u,
        ),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        Paint()
          ..color = _mouth
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8 * u
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // Açık gülümseme: ağız boşluğu + üstte iki diş.
    final mouth = Rect.fromCenter(
      center: Offset(50 * u, my * u),
      width: rx * 0.62 * u,
      height: ry * 0.40 * u,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndCorners(
        mouth,
        topLeft: Radius.circular(rx * 0.12 * u),
        topRight: Radius.circular(rx * 0.12 * u),
        bottomLeft: Radius.circular(rx * 0.31 * u),
        bottomRight: Radius.circular(rx * 0.31 * u),
      ),
    );
    canvas.drawRect(mouth, Paint()..color = _mouth);
    // Dişler üst kenara yapışır.
    canvas.drawRect(
      Rect.fromLTWH(
        mouth.left,
        mouth.top,
        mouth.width,
        mouth.height * 0.38,
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawLine(
      Offset(mouth.center.dx, mouth.top),
      Offset(mouth.center.dx, mouth.top + mouth.height * 0.38),
      Paint()
        ..color = _dark.withValues(alpha: 0.35)
        ..strokeWidth = 1.4 * u,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) => old.pose != pose;
}

/// Maskotun kaldırdığı loop şimşeği — uygulamanın kimlik simgesi.
class MascotBolt extends StatelessWidget {
  const MascotBolt({
    super.key,
    required this.size,
    this.color = _BoltPainter.defaultFace,
    this.shadowColor = _BoltPainter.defaultDepth,
  });

  final double size;
  final Color color;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.5),
      painter: _BoltPainter(face: color, depth: shadowColor),
    );
  }
}

class _BoltPainter extends CustomPainter {
  const _BoltPainter({required this.face, required this.depth});

  /// **Uygulamanın şimşeği beyazdır.** Lig rozetinde varsayılan
  /// `Colors.white`, Kosmoz'da `#E4F4FF`, görev ikonunda (`correct_five`)
  /// `#FFFFFF / #F6EDE4 / #BCAB9E`. Tek istisna Pulsar (`#FFB020`) ve o da
  /// turuncu enerji halkasıyla birlikte anlam kazanıyor.
  ///
  /// Bir dönem burada sarı (`#FEE218 / #E8A900`) duruyordu; o renk tasarım
  /// dilinden değil, üretilmiş bir maskot görselinden örneklenmişti ve
  /// üretimde hiçbir yerde karşılığı yoktu.
  static const defaultFace = Color(0xFFF6EDE4);
  static const defaultDepth = Color(0xFFBCAB9E);

  final Color face;
  final Color depth;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    Path body() => Path()
      ..moveTo(8 * u, 30 * u)
      ..lineTo(52 * u, 4 * u)
      ..lineTo(44 * u, 20 * u)
      ..lineTo(92 * u, 16 * u)
      ..lineTo(48 * u, 46 * u)
      ..lineTo(56 * u, 30 * u)
      ..close();

    void chunky(Path p, Color c) {
      canvas.drawPath(p, Paint()..color = c);
      canvas.drawPath(
        p,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7 * u
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    chunky(body().shift(Offset(0, 4 * u)), depth);
    chunky(body(), face);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

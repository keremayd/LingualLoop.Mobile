import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Puan (XP) simgesi: beş uçlu tombul yıldız.
///
/// Madeni para ikonunun yerini aldı. Para ikonu iki sorun üretiyordu:
/// "harcanabilir" algısı (oysa puan harcanamaz) ve altın bilet ikonuyla aynı
/// renk ailesinde olduğu için yan yana dururken karışması.
///
/// Yeşil seçimi keyfi değil: XP **doğru cevaptan** kazanılır, doğrunun rengi
/// de yeşildir — sayaç kaynağının rengini taşır (§2.9'daki ilerleme barı
/// ilkesinin aynısı). Böylece üç sayaç hem biçim hem renk olarak ayrışır:
/// yeşil yıldız (puan) / mavi çubuk (seviye) / altın bilet.
///
/// §2.5 reçetesi: tombul gövde (aynı yol `StrokeJoin.round` ile konturlanır),
/// altında kalınlık bandı, üst uçlarda açık ton, sol üstte beyaz parlama.
/// 100 birimlik kutuda tanımlıdır.
class PointsStarIcon extends StatelessWidget {
  const PointsStarIcon({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _PointsStarPainter(),
    );
  }
}

class _PointsStarPainter extends CustomPainter {
  const _PointsStarPainter();

  static const _light = Color(0xFFB6E86A);
  static const _face = Color(0xFF93D334);
  static const _depth = Color(0xFF628C22);

  /// İç köşelerin dış yarıçapa oranı. Düşük değer diken gibi sivri,
  /// yüksek değer beşgene yakın bir yıldız üretir.
  static const _innerRatio = 0.47;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;

    // Kalınlık bandı: gövdenin kopyası aşağı kaydırılıp koyu tonda.
    _fillChunky(canvas, _starPath(50 * u, 55 * u, 37 * u), _depth, u);
    // Tombul gövde.
    _fillChunky(canvas, _starPath(50 * u, 48 * u, 37 * u), _face, u);

    // Işık yukarıdan geliyor: üst uçlar açık tonda, sınır keskin (§2.5/3).
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, 44 * u));
    _fillChunky(canvas, _starPath(50 * u, 48 * u, 37 * u), _light, u);
    canvas.restore();

    // Sol üstte ince beyaz parlama (§2.5/5).
    canvas.drawCircle(
      Offset(37 * u, 34 * u),
      5 * u,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  Path _starPath(double cx, double cy, double outer) {
    final path = Path();
    for (var index = 0; index < 10; index++) {
      final radius = index.isEven ? outer : outer * _innerRatio;
      // -pi/2: bir uç tam yukarı baksın, yıldız simetrik dursun.
      final angle = index * math.pi / 5 - math.pi / 2;
      final point = Offset(
        cx + math.cos(angle) * radius,
        cy + math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  /// §2.5/1: aynı yolu hem doldur hem aynı renkle yuvarlak birleşimli
  /// konturla — köşeler yuvarlanır, biçim tombullaşır.
  void _fillChunky(Canvas canvas, Path path, Color color, double u) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9 * u
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PointsStarPainter oldDelegate) => false;
}
